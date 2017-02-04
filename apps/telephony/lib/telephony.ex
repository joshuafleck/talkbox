defmodule Telephony do
  @moduledoc """
  Documentation for Telephony.
  """
  require Logger

  @doc """
  Hello world.

  ## Examples

      iex> Telephony.hello
      :world

  """
  def hello do
    :world
  end

  @spec initiate_conference(String.t, String.t) :: Telephony.Conference.t
  def initiate_conference(chair, participant) do
    # TODO: need to do something if there is already a conference in flight for this chair
    {:ok, conference} = Telephony.Conference.create(chair, participant)
    call_sid = initiate_call_to_chair(conference)
    {:ok, conference} = Telephony.Conference.set_call_sid_on_chair(conference, call_sid)
    conference
  end

  @spec call_or_promote_pending_participant(Telephony.Conference.ParticipantReference.t) :: Telephony.Conference.t
  def call_or_promote_pending_participant(conference_participant_reference) do
    {:ok, conference} = Telephony.Conference.fetch(conference_participant_reference)
    if Telephony.Conference.chair_in_conference?(conference) do
      # It's the participant that joined
      {:ok, conference} = Telephony.Conference.set_call_sid_on_pending_participant(conference, conference_participant_reference.participant_call_sid)
      {:ok, conference} = Telephony.Conference.promote_pending_participant(conference)
      conference
    else
      # It's the chair that joined
      {:ok, conference} = Telephony.Conference.set_call_sid_on_chair(conference, conference_participant_reference.participant_call_sid)
      {:ok, conference} = Telephony.Conference.set_conference_sid(conference, conference_participant_reference.conference_sid)
      call_pending_participant(conference)
    end
  end

  @spec remove_chair_or_participant(Telephony.Conference.ParticipantReference.t) :: Telephony.Conference.t
  def remove_chair_or_participant(conference_participant_reference) do
    call_sid = conference_participant_reference.participant_call_sid
    {:ok, conference} = Telephony.Conference.fetch(conference_participant_reference)
    {:ok, conference} = if Telephony.Conference.chairs_call_sid?(conference, call_sid) do
      # It's the chair that left
      Telephony.Conference.remove_call_sid_on_chair(conference, call_sid)
    else
      # It's a participant that left
      Telephony.Conference.remove_participant(conference, call_sid)
    end
    clear_pointless_conference(conference)
  end

  @spec remove_conference(Telephony.Conference.Reference.t) :: Telephony.Conference.t
  def remove_conference(conference_reference) do
    {:ok, conference} = Telephony.Conference.fetch(conference_reference)
    hangup_pending_and_remove_conference(conference)
  end

  @spec remove_pending_participant(Telephony.Conference.PendingParticipantReference.t) :: Telephony.Conference.t
  def remove_pending_participant(pending_participant_reference) do
    {:ok, conference} = Telephony.Conference.remove_pending_participant(pending_participant_reference)
    clear_pointless_conference(conference)
  end

  @spec hangup_pending_participant(Telephony.Conference.PendingParticipantReference.t) :: Telephony.Conference.t
  def hangup_pending_participant(pending_participant_reference) do
    {:ok, conference} = Telephony.Conference.fetch_by_pending_participant(pending_participant_reference)
    hangup_pending_participant_call(conference)
    conference
  end

  @spec add_participant(Telephony.Conference.PendingParticipantReference.t) :: Telephony.Conference.t
  def add_participant(pending_participant_reference) do
    {:ok, conference} = Telephony.Conference.add_pending_participant(pending_participant_reference)
    call_pending_participant(conference)
  end

  @spec update_call_status_of_pending_participant(Telephony.Conference.PendingParticipantReference.t, String.t, non_neg_integer) :: Telephony.Conference.t
  def update_call_status_of_pending_participant(pending_participant_reference, call_status, sequence_number) do
    {:ok, conference} = Telephony.Conference.update_call_status_of_pending_participant(pending_participant_reference, call_status, sequence_number)
    conference
  end

  @spec clear_pointless_conference(Telephony.Conference.t) :: Telephony.Conference.t
  defp clear_pointless_conference(conference) do
    if Telephony.Conference.any_participants?(conference) do
      conference
    else
      if Telephony.Conference.chair_in_conference?(conference) do
        {:ok, _call_sid} = get_env(:provider).kick_participant_from_conference(conference.sid, conference.chair.call_sid)
      end
      hangup_pending_and_remove_conference(conference)
    end
  end

  @spec hangup_pending_and_remove_conference(Telephony.Conference.t) :: Telephony.Conference.t
  defp hangup_pending_and_remove_conference(conference) do
    if Telephony.Conference.pending_participant?(conference) do
      hangup_pending_participant_call(conference)
    end
    {:ok, conference} = Telephony.Conference.remove(conference)
    conference
  end

  @spec hangup_pending_participant_call(Telephony.Conference.t) :: String.t
  defp hangup_pending_participant_call(conference) do
    case conference.pending_participant.call_sid do
      call_sid when not is_nil(call_sid) ->
        # NOTE: we'll receive a call status update event when the participant's call ends, which will trigger the actual removal of the participant
        {:ok, call_sid} = get_env(:provider).hangup(call_sid)
        call_sid
      call_sid ->
        call_sid
    end
  end

  @spec call_pending_participant(Telephony.Conference.t) :: Telephony.Conference.t
  defp call_pending_participant(conference) do
    pending_participant_call_sid = initiate_call_to_pending_participant(conference)
    # NOTE: this could fail if the participant has already been promoted (unlikely but possible)
    {:ok, conference} = Telephony.Conference.set_call_sid_on_pending_participant(conference, pending_participant_call_sid)
    conference
  end

  @spec initiate_call_to_chair(Telephony.Conference.t) :: String.t
  defp initiate_call_to_chair(conference) do
    {:ok, call_sid} = get_env(:provider).call(
      to: conference.chair.identifier,
      from: get_env(:cli),
      url: Telephony.Callbacks.chair_answered(conference),
      status_callback: Telephony.Callbacks.chair_status_callback(conference),
      status_callback_events: ~w(completed))
    call_sid
  end

  @spec initiate_call_to_pending_participant(Telephony.Conference.t) :: String.t
  defp initiate_call_to_pending_participant(conference) do
    {:ok, call_sid} = get_env(:provider).call(
      to: conference.pending_participant.identifier,
      from: get_env(:cli),
      url: Telephony.Callbacks.pending_participant_answered(conference),
      status_callback: Telephony.Callbacks.participant_status_callback(conference),
      status_callback_events: ~w(initiated ringing completed))
    call_sid
  end

  @doc """
  Get a setting from the application environment.
  If the setting is lazy, will evaluate and return the setting.
  """
  @spec get_env(atom) :: any
  def get_env(name) do
    setting = Application.get_env(:telephony, name)
    if is_function(setting) do
      setting.()
    else
      setting
    end
  end
end
