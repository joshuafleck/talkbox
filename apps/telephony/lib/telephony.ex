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
  Finds or initialises a conference, adding a pending participant to the
  conference and, if there was a prexisting conference, dials a new call
  leg, otherwise, dials the chair's call leg.

  In case of a new conference we abstain from dialling the participant's call
  leg until we've confirmed we have joined the chair's leg to the conference.
  This is to ensure that the participant does not end up in an empty conference.
  """
  @spec add_participant_or_initiate_conference(String.t, String.t) :: response
  def add_participant_or_initiate_conference(chairperson, destination) do
    case Telephony.Conference.fetch(chairperson) do
      nil ->
        initiate_conference(chairperson, destination)
      {:ok, conference} ->
        add_participant(conference, destination)
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
  @spec acknowledge_call_joined(Telephony.Conference.internal_identifier, String.t, String.t) :: response
  def acknowledge_call_joined(conference_identifier, providers_identifier, providers_call_identifier) do
    {:ok, conference} = Telephony.Conference.fetch(conference_identifier)
    {:ok, conference} = Telephony.Conference.set_providers_identifier(conference, providers_identifier)
    call = Enum.find(Map.values(conference.calls), fn call -> call.providers_identifier == providers_call_identifier end)
    if Telephony.Conference.chairpersons_call?(conference, call.identifier) do
      call_pending_participants(conference)
    end
    {:ok, conference}
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
  @spec acknowledge_call_left(Telephony.Conference.internal_identifier, String.t) :: Telephony.Conference.t | nil
  def acknowledge_call_left(conference_identifier, providers_call_identifier) do
    case Telephony.Conference.fetch(conference_identifier) do
      {:ok, conference} ->
        {:ok, conference} = Telephony.Conference.remove_call(conference, providers_call_identifier)
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
  @spec remove_conference(Telephony.Conference.internal_identifier) :: Telephony.Conference.t | nil
  def remove_conference(conference_identifier) do
    case Telephony.Conference.fetch(conference_identifier) do
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
  @spec remove_call(Telephony.Conference.internal_identifier, Telephony.Conference.internal_identifier) :: Telephony.Conference.t
  def remove_call(conference_identifier, call_identifier) do
    case Telephony.Conference.fetch(conference_identifier) do
      {:ok, conference} ->
        {:ok, conference} = Telephony.Conference.remove_call(conference, call_identifier)
        clear_pointless_conference(conference)
      _ ->
        nil
    end
  end

  @doc """
  Call this to hang up the call leg for the pending participant. For example, if you decide
  you want to cancel your attempt to call a participant.

  Note that this does not remove the pending participant from the conference state as there
  will be a subsequent message from the telephony provider telling us that the leg has failed
  to connect, which will be handled in `remove_pending_participant/1`.
  """
  @spec hangup_call(Telephony.Conference.internal_identifier, Telephony.Conference.internal_identifier) :: Telephony.Conference.t
  def hangup_call(conference_identifier, call_identifier) do
    {:ok, conference} = Telephony.Conference.fetch(conference_identifier)
    call = Map.get(conference.calls, call_identifier)
    case call.status do
      "in-progress" ->
        kick_call(conference, call)
      _ ->
        {:ok, providers_call_identifier} = @telephony_provider.hangup(call.providers_identifier)
    end
    conference
  end

  @spec kick_call(Telephony.Conference.t, Telephone.Conference.Call.t) :: {:ok, String.t} | {:error, String.t, number}
  defp kick_call(conference, call) do
    @telephony_provider.kick_participant_from_conference(conference.providers_identifier, call.providers_identifier)
  end

  @doc """
  Called when we receive a notification from the telephony provider that the status of the
  call leg for the pending participant has changed.
  """
  @spec update_status_of_call(Telephony.Conference.internal_identifier, Telephony.Conference.internal_identifier, String.t, String.t, non_neg_integer) :: Telephony.Conference.t
  def update_status_of_call(conference_identifier, call_identifier, providers_call_identifier, call_status, sequence_number) do
    {:ok, conference} = Telephony.Conference.fetch(conference_identifier)
    {:ok, conference} = Telephony.Conference.set_providers_identifier_on_call(conference, call_identifier, providers_call_identifier)
    {:ok, conference} = Telephony.Conference.update_status_of_call(conference, call_identifier, call_status, sequence_number)
    conference
  end

  @spec initiate_conference(String.t, String.t) :: response
  defp initiate_conference(chairperson, destination) do
    with  {:ok, conference} <- Telephony.Conference.create(chairperson, destination),
          {:ok, providers_call_identifier} <- initiate_call(conference.identifier, Telephony.Conference.chairpersons_call(conference).identifier, chairperson),
          {:ok, conference} <- Telephony.Conference.set_providers_identifier_on_call(conference, Telephony.Conference.chairpersons_call(conference).identifier, providers_call_identifier)
    do
      {:ok, conference}
    else
      {:error, message} ->
        {:error, message, nil}
    end
  end

  @spec add_participant(Telephony.Conference.t, String.t) :: response
  defp add_participant(conference, destination) do
    {:ok, conference} = Telephony.Conference.add_call(conference, destination)
    call_pending_participants(conference)
    {:ok, conference}
  end

  @spec clear_pointless_conference(Telephony.Conference.t) :: Telephony.Conference.t
  defp clear_pointless_conference(conference) do
    chairpersons_call = Telephony.Conference.chairpersons_call(conference)
    number_of_calls = Enum.count(Map.values(conference.calls))
    if chairpersons_call != nil && number_of_calls == 1 do
      kick_call(conference, chairpersons_call)
    end

    conference
  end

  @spec hangup_pending_and_remove_conference(Telephony.Conference.t) :: Telephony.Conference.t
  defp hangup_pending_and_remove_conference(conference) do
    Enum.filter_map(Map.values(conference.calls), fn call -> call.providers_identifier == nil end, fn call -> hangup_call(conference.identifier, call.identifier) end)
    {:ok, conference} = Telephony.Conference.remove(conference)
    conference
  end

  @spec call_pending_participants(Telephony.Conference.t) :: []
  defp call_pending_participants(conference) do
    Map.values(conference.calls)
    |> Enum.filter(fn call -> call.providers_identifier == nil end)
    |> Enum.map(fn call -> initiate_call(conference.identifier, call.identifier, call.destination) end)
  end

  @spec initiate_call(Telephony.Conference.internal_identifier, Telephony.Conference.internal_identifier, String.t) :: {:ok, String.t} | {:error, String.t}
  defp initiate_call(conference_identifier, call_identifier, destination) do
    result = @telephony_provider.call(
      to: destination,
      from: get_env(:cli),
      url: Telephony.Callbacks.call_answered(conference_identifier, call_identifier),
      status_callback: Telephony.Callbacks.call_status_updated(conference_identifier, call_identifier),
      status_callback_events: ~w(initiated ringing answered completed))
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
