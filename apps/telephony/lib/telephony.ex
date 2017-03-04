defmodule Telephony do
  @moduledoc """
  The purpose of this module is to encapsulate the business logic
  of the telephony system. It is responsible for initiating and hanging
  up call legs as well as managing the state of the calls through the
  `Telephony.Conference` module.

  TODO:
    * Upon startup, query the telephony provider for a list of in-progress conferences with which to prepopulate the local conference store.
  """
  require Logger

  @telephony_provider Application.get_env(:telephony, :provider)

  @type success :: {:ok, Telephony.Conference.t}
  @type fail :: {:error, String.t, Telephony.Conference.t | nil}
  @type response :: success | fail

  @doc """
  Initiates a conference by creating a conference record and
  dialling the chair's call leg. We abstain from dialling the
  participant's call leg until we've confirmed we have joined
  the chair's leg to the conference. This is to ensure that the
  participant does not end up in an empty conference.
  """
  @spec initiate_conference(String.t, String.t) :: response
  def initiate_conference(chair, participant) do
    with  {:ok, conference} <- Telephony.Conference.create(chair, participant),
          {:ok, call_sid} <- initiate_call_to_chair(conference),
          {:ok, conference} <- Telephony.Conference.set_call_sid_on_chair(conference, call_sid)
    do
      {:ok, conference}
    else
      {:error, message} ->
        {:error, message, nil}
    end
  end

  @doc """
  Called when we receive notification that a participant has joined the conference.

  If the chair has not yet been joined to the conference, this updates the
  call leg details for the chair on the conference and will then initiate the
  participant's call.

  Otherwise, this updates the call leg details for the pending participant and
  promotes the participant from pending to a fully-fledged participant.

  The telephony provider will tell us when a participant has joined
  the conference, but it's up to us to figure out whether it was the
  chair's leg or the pending participant's leg. There is nothing that
  guarantees that we've set the participant's call_sid in the conference
  state before the telephony provider sends us a message telling us a
  participant has joined the conference, thus we cannot rely on matching
  the participant based on its call_sid.
  """
  @spec call_or_promote_pending_participant(Telephony.Conference.ParticipantReference.t) :: response
  def call_or_promote_pending_participant(conference_participant_reference) do
    {:ok, conference} = Telephony.Conference.fetch(conference_participant_reference)
    if Telephony.Conference.chair_in_conference?(conference) do
      # It's the participant that joined
      {:ok, conference} = Telephony.Conference.set_call_sid_on_pending_participant(conference, conference_participant_reference.participant_call_sid)
      {:ok, conference} = Telephony.Conference.promote_pending_participant(conference)
      {:ok, conference}
    else
      # It's the chair that joined
      {:ok, conference} = Telephony.Conference.set_call_sid_on_chair(conference, conference_participant_reference.participant_call_sid)
      {:ok, conference} = Telephony.Conference.set_conference_sid(conference, conference_participant_reference.conference_sid)
      call_pending_participant(conference)
    end
  end

  @doc """
  Called when we receive notification that a participant has left the conference.

  If the provided participant reference matches the call_sid of the chair,
  the chair's call_sid will be cleared on the conference. Otherwise, the
  matching participant is looked up in the participant's list and removed.

  Depending on who is remaining in the conference, the remaining call legs may
  be hung up and the conference cleared. If there are any participants
  (including pending participants), then the conference will carry on (even if
  the chair has left). The reasoning behind this is to allow the chair to reconnect
  after becoming disconnected from the conference. If, however, it is just the
  chair remaining in the conference then their call leg will be hung up and the
  conference cleared.
  """
  @spec remove_chair_or_participant(Telephony.Conference.ParticipantReference.t) :: Telephony.Conference.t | nil
  def remove_chair_or_participant(conference_participant_reference) do
    call_sid = conference_participant_reference.participant_call_sid
    case Telephony.Conference.fetch(conference_participant_reference) do
      {:ok, conference} ->
        {:ok, conference} = if Telephony.Conference.chairs_call_sid?(conference, call_sid) do
          # It's the chair that left
          Telephony.Conference.remove_call_sid_on_chair(conference, call_sid)
        else
          # It's a participant that left
          Telephony.Conference.remove_participant(conference, call_sid)
        end
        clear_pointless_conference(conference)
      _ ->
        nil
    end
  end

  @doc """
  Called when we receive notification that a conference has ended.

  This will clear the conference and hang up any pending participant call leg.
  This is done because if the conference has ended then there is no way to
  salvage it and there is no path for reconnecting to it.
  """
  @spec remove_conference(Telephony.Conference.Reference.t) :: Telephony.Conference.t | nil
  def remove_conference(conference_reference) do
    case Telephony.Conference.fetch(conference_reference) do
      {:ok, conference} ->
        hangup_pending_and_remove_conference(conference)
      _ ->
        nil
    end
  end

  @doc """
  Called when we receive notification that a pending participant's call leg has failed to connect.

  This will remove the pending participant and may end the conference as described in `remove_chair_or_participant/1`
  """
  @spec remove_pending_participant(Telephony.Conference.PendingParticipantReference.t) :: Telephony.Conference.t
  def remove_pending_participant(pending_participant_reference) do
    {:ok, conference} = Telephony.Conference.remove_pending_participant(pending_participant_reference)
    clear_pointless_conference(conference)
  end

  @doc """
  Call this to hang up the call leg for the pending participant. For example, if you decide
  you want to cancel your attempt to call a participant.

  Note that this does not remove the pending participant from the conference state as there
  will be a subsequent message from the telephony provider telling us that the leg has failed
  to connect, which will be handled in `remove_pending_participant/1`.
  """
  @spec hangup_pending_participant(Telephony.Conference.PendingParticipantReference.t) :: Telephony.Conference.t
  def hangup_pending_participant(pending_participant_reference) do
    {:ok, conference} = Telephony.Conference.fetch_by_pending_participant(pending_participant_reference)
    hangup_pending_participant_call(conference)
    conference
  end

  @doc """
  Call this to remove a participant's call leg from the conference.

  Note that this does not remove the participant from the conference state as there
  will be a subsequent message from the telephony provider telling us that the leg has left,
  which will be handled in `remove_chair_or_participant/1`.
  """
  @spec hangup_participant(Telephony.Conference.ParticipantReference.t) :: {:ok, String.t} | {:error, String.t, number}
  def hangup_participant(conference_participant_reference) do
    call_sid = conference_participant_reference.participant_call_sid
    {:ok, conference} = Telephony.Conference.fetch(conference_participant_reference)
    @telephony_provider.kick_participant_from_conference(conference.sid, call_sid)
  end

  @doc """
  Call this to add a participant to the conference.

  This will store the pending participant on the conference state and
  will initiate the call leg to the pending participant.
  """
  @spec add_participant(Telephony.Conference.PendingParticipantReference.t) :: response
  def add_participant(pending_participant_reference) do
    {:ok, conference} = Telephony.Conference.add_pending_participant(pending_participant_reference)
    call_pending_participant(conference)
  end

  @doc """
  Called when we receive a notification from the telephony provider that the status of the
  call leg for the pending participant has changed.
  """
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
        {:ok, _call_sid} = @telephony_provider.kick_participant_from_conference(conference.sid, conference.chair.call_sid)
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

  @spec hangup_pending_participant_call(Telephony.Conference.t) :: String.t | nil
  defp hangup_pending_participant_call(conference) do
    case conference.pending_participant.call_sid do
      nil ->
        nil
      call_sid ->
        # NOTE: we'll receive a call status update event when the participant's call ends, which will trigger the actual removal of the participant
        {:ok, call_sid} = @telephony_provider.hangup(call_sid)
        call_sid
    end
  end

  @spec call_pending_participant(Telephony.Conference.t) :: response
  defp call_pending_participant(conference) do
    case initiate_call_to_pending_participant(conference) do
      {:ok, pending_participant_call_sid} ->
        # NOTE: this could fail if the participant has already been promoted (unlikely but possible)
        {:ok, conference} = Telephony.Conference.set_call_sid_on_pending_participant(conference, pending_participant_call_sid)
        {:ok, conference}
      {:error, message} ->
        conference = remove_pending_participant(Telephony.Conference.pending_participant_reference(conference))
        {:error, message, conference}
    end
  end

  @spec initiate_call_to_chair(Telephony.Conference.t) :: {:ok, String.t} | {:error, String.t}
  defp initiate_call_to_chair(conference) do
    reference = Telephony.Conference.reference(conference)
    case @telephony_provider.call(
      to: conference.chair.identifier,
      from: get_env(:cli),
      url: Telephony.Callbacks.chair_answered(reference),
      status_callback: Telephony.Callbacks.chair_status_callback(reference),
      status_callback_events: ~w(completed)) do
      {:ok, call_sid} ->
        {:ok, call_sid}
      {:error, message, _} ->
        {:error, message}
    end
  end

  @spec initiate_call_to_pending_participant(Telephony.Conference.t) :: {:ok, String.t} | {:error, String.t}
  defp initiate_call_to_pending_participant(conference) do
    pending_participant_reference = Telephony.Conference.pending_participant_reference(conference)
    result = @telephony_provider.call(
      to: conference.pending_participant.identifier,
      from: get_env(:cli),
      url: Telephony.Callbacks.pending_participant_answered(pending_participant_reference),
      status_callback: Telephony.Callbacks.participant_status_callback(pending_participant_reference),
      status_callback_events: ~w(initiated ringing completed))
    case result do
      {:error, message, _} ->
        {:error, message}
      result ->
        result
    end
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
