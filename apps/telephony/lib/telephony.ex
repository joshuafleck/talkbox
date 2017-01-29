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

  def initiate_conference(chair: chair, participant: participant) do
    conference = Telephony.Conference.create(chair, participant)
    call_sid = initiate_call_to_chair(conference)
    Telephony.Conference.set_call_sid_on_chair(chair, conference.identifier, call_sid)
  end

  def call_or_promote_pending_participant(
        chair: chair,
        conference: conference_identifier,
        call_sid: call_sid,
        conference_sid: conference_sid) do
    conference = Telephony.Conference.fetch(chair, conference_identifier)
    if Telephony.Conference.chair_joined_conference?(conference) do
      Telephony.Conference.set_call_sid_on_pending_participant(chair, conference_identifier, conference.pending_participant.identifier, call_sid)
      Telephony.Conference.promote_pending_participant(chair, conference_identifier, conference.pending_participant.identifier)
    else
      Telephony.Conference.set_call_sid_on_chair(chair, conference_identifier, call_sid)
      Telephony.Conference.set_conference_sid(chair, conference_identifier, conference_sid)
      call_pending_participant(conference, chair, conference_identifier)
    end
  end

  def remove_chair_or_participant(
        chair: chair,
        conference: conference_identifier,
        call_sid: call_sid) do
    conference = Telephony.Conference.fetch(chair, conference_identifier)
    conference = if Telephony.Conference.chairs_call_sid?(conference, call_sid) do
      Telephony.Conference.remove_call_sid_on_chair(chair, conference_identifier, call_sid)
    else
      Telephony.Conference.remove_participant(chair, conference_identifier, call_sid)
    end
    clear_pointless_conference(conference, chair, conference_identifier)
  end

  def remove_conference(chair: chair, conference: conference_identifier) do
    Telephony.Conference.remove(chair, conference_identifier)
  end

  def remove_pending_participant(
        chair: chair,
        conference: conference_identifier,
        pending_participant: pending_participant) do
    conference = Telephony.Conference.remove_pending_participant(chair, conference_identifier, pending_participant)
    clear_pointless_conference(conference, chair, conference_identifier)
  end

  def hangup_pending_participant(
        chair: chair,
        conference: conference_identifier,
        pending_participant: pending_participant) do
    %{pending_participant: %{call_sid: call_sid}} = Telephony.Conference.fetch_by_pending_participant(chair, conference_identifier, pending_participant)
    case call_sid do
      call_sid when not is_nil(call_sid) ->
        # NOTE: we'll receive a call status update event when the participant's call ends, which will trigger the actual removal of the participant
        get_env(:provider).hangup(call_sid)
    end
  end

  def add_participant(chair: chair, conference: conference_identifier, participant: participant) do
    conference = Telephony.Conference.add_pending_participant(chair, conference_identifier, participant)
    call_pending_participant(conference, chair, conference_identifier)
  end

  def update_call_status_of_pending_participant(
        chair: chair,
        conference: conference_identifier,
        pending_participant: pending_participant,
        call_status: call_status,
        sequence_number: sequence_number) do
    Telephony.Conference.update_call_status_of_pending_participant(chair, conference_identifier, pending_participant, call_status, sequence_number)
  end

  defp clear_pointless_conference(conference, chair, conference_identifier) do
    unless Telephony.Conference.any_participants?(conference) do
      remove_conference(chair: chair, conference: conference_identifier)
      if Telephony.Conference.chair_in_conference?(conference) do
        get_env(:provider).kick_participant_from_conference(conference.sid, conference.chair.call_sid)
      end
    end
  end

  defp call_pending_participant(conference, chair, conference_identifier) do
    pending_participant_call_sid = initiate_call_to_pending_participant(conference)
    # NOTE: this could fail if the participant has already been promoted (unlikely but possible)
    Telephony.Conference.set_call_sid_on_pending_participant(chair, conference_identifier, conference.pending_participant.identifier, pending_participant_call_sid)
  end

  defp initiate_call_to_chair(conference) do
    get_env(:provider).call(
      to: conference.chair.identifier,
      from: get_env(:cli),
      url: Telephony.Callbacks.chair_answered(conference),
      status_callback: Telephony.Callbacks.chair_status_callback(conference),
      status_callback_events: ~w(completed))
  end

  defp initiate_call_to_pending_participant(conference) do
    get_env(:provider).call(
      to: conference.pending_participant.identifier,
      from: get_env(:cli),
      url: Telephony.Callbacks.pending_participant_answered(conference),
      status_callback: Telephony.Callbacks.participant_status_callback(conference),
      status_callback_events: ~w(initiated ringing completed))
  end

  def get_env(name) do
    setting = Application.get_env(:telephony, name)
    if is_function(setting) do
      setting.()
    else
      setting
    end
  end
end
