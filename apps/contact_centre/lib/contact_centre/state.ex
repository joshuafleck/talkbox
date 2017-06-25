defmodule ContactCentre.State do
  @moduledoc """
  The purpose of this module is to maintain the state
  of the ContactCentre system and expose functions for
  altering the state of the system.
  """
  use GenServer

  @type success :: {:ok, ContactCentre.State.Conference.t}
  @type fail :: {:error, String.t, ContactCentre.State.Conference.t | nil}
  @type response :: success | fail
  @type store :: %{required(ContactCentre.State.Indentifier.t) => ContactCentre.State.Conference.t}

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  # Client

  @doc """
  Finds or initialises a conference, adding a pending participant to the
  conference and, if there was a prexisting conference, dials a new call
  leg, otherwise, dials the chair's call leg.

  In case of a new conference we abstain from dialling the participant's call
  leg until we've confirmed we have joined the chair's leg to the conference.
  This is to ensure that the participant does not end up in an empty conference.
  """
  @spec add_participant_or_initiate_conference(String.t, String.t, String.t | nil) :: response
  def add_participant_or_initiate_conference(chairperson, destination, conference_identifier) do
    GenServer.call(__MODULE__, {:add_participant_or_initiate_conference, chairperson, destination, conference_identifier})
  end

  @doc """
  Called when we receive a notification from the telephony provider that the status of the
  call leg for the pending participant has changed.
  """
  @spec update_status_of_call(ContactCentre.State.Intentifier.t, ContactCentre.State.Intentifier.t, String.t, String.t, non_neg_integer) :: response
  def update_status_of_call(conference_identifier, call_identifier, providers_call_identifier, call_status, sequence_number) do
    GenServer.call(__MODULE__, {:update_status_of_call, conference_identifier, call_identifier, providers_call_identifier, call_status, sequence_number})
  end

  @doc """
  Call this to hang up the call leg for the pending participant. For example, if you decide
  you want to cancel your attempt to call a participant.

  Note that this does not remove the pending participant from the conference state as there
  will be a subsequent message from the telephony provider telling us that the leg has failed
  to connect, which will be handled in `remove_call`.
  """
  @spec hangup_call(ContactCentre.State.Intentifier.t, ContactCentre.State.Intentifier.t) :: response
  def hangup_call(conference_identifier, call_identifier) do
    GenServer.call(__MODULE__, {:hangup_call, conference_identifier, call_identifier})
  end

  @doc """
  Called when we receive notification that a pending participant's call leg has failed to connect.

  This will remove the pending participant and may end the conference if the chairperson is all alone.
  """
  @spec remove_call(ContactCentre.State.Intentifier.t, ContactCentre.State.Intentifier.t) :: response
  def remove_call(conference_identifier, call_identifier) do
    GenServer.call(__MODULE__, {:remove_call, conference_identifier, call_identifier})
  end

  @doc """
  Called when we receive notification that a conference has ended.

  This will clear the conference and hang up any pending participant call leg.
  This is done because if the conference has ended then there is no way to
  salvage it and there is no path for reconnecting to it.
  """
  @spec remove_conference(ContactCentre.State.Intentifier.t) :: response
  def remove_conference(conference_identifier) do
    GenServer.call(__MODULE__, {:remove_conference, conference_identifier})
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
  @spec acknowledge_call_left(ContactCentre.State.Intentifier.t, String.t) :: response
  def acknowledge_call_left(conference_identifier, providers_call_identifier) do
    GenServer.call(__MODULE__, {:acknowledge_call_left, conference_identifier, providers_call_identifier})
  end

  @doc """
  Called when we receive notification that a participant has joined the conference.

  If the chair has not yet been joined to the conference, this updates the
  call leg details for the chair on the conference and will then initiate the
  participant's call.
  """
  @spec acknowledge_call_joined(ContactCentre.State.Intentifier.t, String.t, String.t) :: response
  def acknowledge_call_joined(conference_identifier, providers_identifier, providers_call_identifier) do
    GenServer.call(__MODULE__, {:acknowledge_call_joined, conference_identifier, providers_identifier, providers_call_identifier})
  end

  # Server

  def handle_call({:add_participant_or_initiate_conference, chairperson, destination, conference_identifier}, _from, state) do
    conference = case Map.get(state, conference_identifier) do
      nil ->
        initiate_conference(chairperson, destination)
      conference ->
        add_participant(conference, destination)
    end
    {:reply, {:ok, conference}, Map.put(state, conference.identifier, conference)}
  end

  def handle_call({:acknowledge_call_joined, conference_identifier, providers_identifier, providers_call_identifier}, _from, state) do
    with_conference_and_call(state, conference_identifier, providers_call_identifier, fn (conference, call) ->
      {:ok, conference} = ContactCentre.State.Conference.set_providers_identifier(conference, providers_identifier)
      if ContactCentre.State.Conference.chairpersons_call?(conference, call.identifier) do
        call_pending_participants(conference)
      end
      {:reply, {:ok, conference}, Map.put(state, conference_identifier, conference)}
    end)
  end

  def handle_call({:acknowledge_call_left, conference_identifier, providers_call_identifier}, _from, state) do
    with_conference_and_call(state, conference_identifier, providers_call_identifier, fn (conference, call) ->
      conference = conference
      |> ContactCentre.State.Conference.remove_call(call)
      |> clear_pointless_conference()
      {:reply, {:ok, conference}, Map.put(state, conference_identifier, conference)}
    end)
  end

  def handle_call({:remove_conference, conference_identifier}, _from, state) do
    with_conference(state, conference_identifier, fn conference ->
      conference = hangup_requested_calls(conference)
      {:reply, {:ok, conference}, Map.delete(state, conference_identifier)}
    end)
  end

  def handle_call({:remove_call, conference_identifier, call_identifier}, _from, state) do
    with_conference_and_call(state, conference_identifier, call_identifier, fn (conference, call) ->
      conference = conference
      |> ContactCentre.State.Conference.remove_call(call)
      |> clear_pointless_conference()
      {:reply, {:ok, conference}, Map.put(state, conference_identifier, conference)}
    end)
  end

  def handle_call({:hangup_call, conference_identifier, call_identifier}, _from, state) do
    with_conference_and_call(state, conference_identifier, call_identifier, fn (conference, call) ->
      request_to_hangup_or_remove_call(conference, call)
      {:reply, {:ok, conference}, state}
    end)
  end

  def handle_call({:update_status_of_call, conference_identifier, call_identifier, providers_call_identifier, call_status, sequence_number}, _from, state) do
    with_conference_and_call(state, conference_identifier, call_identifier, fn (conference, call) ->
      with {:ok, conference, call} <- ContactCentre.State.Conference.set_providers_identifier_on_call(conference, call, providers_call_identifier),
      {:ok, conference, _} <- ContactCentre.State.Conference.update_status_of_call(conference, call, call_status, sequence_number) do
        {:reply, {:ok, conference}, Map.put(state, conference_identifier, conference)}
      else
        {:error, message} ->
          {:reply, {:error, message, conference}, Map.put(state, conference_identifier, conference)}
      end
    end)
  end

  # Internals

  @spec initiate_conference(String.t, String.t) :: ContactCentre.State.Conference.t
  defp initiate_conference(chairperson, destination) do
    conference = ContactCentre.State.Conference.new(chairperson, destination)
    chairpersons_call = ContactCentre.State.Conference.chairpersons_call(conference)
    request_call(chairpersons_call, conference)
    conference
  end

  @spec add_participant(ContactCentre.State.Conference.t, String.t) :: ContactCentre.State.Conference.t
  defp add_participant(conference, destination) do
    conference
    |> ContactCentre.State.Conference.add_call(destination)
    |> call_pending_participants()
  end

  @spec clear_pointless_conference(ContactCentre.State.Conference.t) :: ContactCentre.State.Conference.t
  defp clear_pointless_conference(conference) do
    if ContactCentre.State.Conference.chairperson_is_alone?(conference) do
      chairpersons_call = ContactCentre.State.Conference.chairpersons_call(conference)
      request_to_hangup_or_remove_call(conference, chairpersons_call)
    end
    conference
  end

  @spec hangup_requested_calls(ContactCentre.State.Conference.t) :: ContactCentre.State.Conference.t
  defp hangup_requested_calls(conference) do
    conference
    |> ContactCentre.State.Conference.requested_calls()
    |> Enum.each(fn call ->
      request_to_hangup_or_remove_call(conference, call)
    end)
    conference
  end

  @spec request_to_hangup_or_remove_call(ContactCentre.State.Conference.t, ContactCentre.State.Call.t) :: ContactCentre.State.Conference.t
  def request_to_hangup_or_remove_call(conference, call) do
    if ContactCentre.State.Call.in_conference?(call) do
      Events.publish(%Events.RemoveRequested{
            conference: conference.identifier,
            providers_identifier: conference.providers_identifier,
            call: call.identifier,
            providers_call_identifier: call.providers_identifier})
    else
      Events.publish(%Events.HangupRequested{
            conference: conference.identifier,
            call: call.identifier,
            providers_call_identifier: call.providers_identifier})
    end
    conference
  end

  @spec call_pending_participants(ContactCentre.State.Conference.t) :: ContactCentre.State.Conference.t
  defp call_pending_participants(conference) do
    conference
    |> ContactCentre.State.Conference.pending_calls()
    |> Enum.each(fn call ->
      request_call(call, conference)
    end)
    conference
  end

  @spec request_call(ContactCentre.State.Call.t, ContactCentre.State.Conference.t) :: ContactCentre.State.Conference.t
  defp request_call(call, conference) do
    Events.publish(%Events.CallRequested{
          destination: call.destination,
          conference: conference.identifier,
          call: call.identifier})
    conference
  end

  @spec with_conference(store, ContactCentre.State.Indentifier.t, (ContactCentre.State.Conference.t -> response)) :: {:reply, response, store}
  defp with_conference(conferences, identifier, block) do
    case Map.get(conferences, identifier) do
      nil ->
        {:reply, {:error, "matching conference not found", nil}, conferences}
      conference ->
        block.(conference)
    end
  end

  @spec with_conference_and_call(store, ContactCentre.State.Indentifier.t, ContactCentre.State.Indentifier.t | String.t, ((ContactCentre.State.Conference.t, ContactCentre.State.Call.t) -> response)) :: {:reply, response, store}
  defp with_conference_and_call(conferences, identifier, call_identifier, block) do
    with_conference(conferences, identifier, fn conference ->
      case ContactCentre.State.Conference.search_for_call(conference, call_identifier) do
        nil ->
          {:reply, {:error, "matching call not found", conference}, conferences}
        call ->
          block.(conference, call)
      end
    end)
  end
end