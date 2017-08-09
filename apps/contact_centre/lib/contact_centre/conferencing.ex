defmodule ContactCentre.Conferencing do
  @moduledoc """
  Encapsulates the business logic around conferencing. Exposes
  an API for the manipulation of conferences, which are represented
  as processes and stored in a registry.
  """
  use GenServer

  # Client

  @doc """
  Finds or initialises a conference, adding a pending participant to the
  conference and, if there was a prexisting conference, dials a new call
  leg, otherwise, dials the chair's call leg.

  In case of a new conference we abstain from dialling the participant's call
  leg until we've confirmed we have joined the chair's leg to the conference.
  This is to ensure that the participant does not end up in an empty conference.
  """
  @spec add_participant_or_initiate_conference(String.t, String.t, String.t | nil) :: :ok
  def add_participant_or_initiate_conference(chairperson, destination, conference_identifier) do
    case conference_identifier do
      nil ->
        conference = initiate_conference(chairperson, destination)
        {:ok, _} = GenServer.start(__MODULE__, conference, name: via_tuple(conference.identifier))
        Events.publish(%Events.ConferenceCreated{user: chairperson, conference: conference})
        :ok
      conference_identifier ->
        GenServer.cast(via_tuple(conference_identifier), {:add_participant, destination})
    end
  end

  @doc """
  Called when we receive a notification from the telephony provider that the status of the
  call leg has changed.
  """
  @spec update_status_of_call(ContactCentre.Conferencing.Identifier.t, ContactCentre.Conferencing.Identifier.t, String.t, String.t, non_neg_integer) :: :ok
  def update_status_of_call(conference_identifier, call_identifier, providers_call_identifier, call_status, sequence_number) do
    GenServer.cast(via_tuple(conference_identifier), {:update_status_of_call, call_identifier, providers_call_identifier, call_status, sequence_number})
  end

  @doc """
  Call this to hang up a call leg. For example, if you decide
  you want to cancel your attempt to call a participant.

  Note that this does not remove the call from the conference state as there
  will be a subsequent message from the telephony provider telling us that the leg has failed
  to connect, which will be handled in `remove_call`.
  """
  @spec hangup_call(ContactCentre.Conferencing.Identifier.t, ContactCentre.Conferencing.Identifier.t) :: :ok
  def hangup_call(conference_identifier, call_identifier) do
    GenServer.cast(via_tuple(conference_identifier), {:hangup_call, call_identifier})
  end

  @doc """
  Called when we receive notification that a call leg has failed to connect.

  This will remove the call and may end the conference if the chairperson is all alone.
  """
  @spec remove_call(ContactCentre.Conferencing.Identifier.t, ContactCentre.Conferencing.Identifier.t, String.t | nil) :: :ok
  def remove_call(conference_identifier, call_identifier, reason \\ nil) do
    GenServer.cast(via_tuple(conference_identifier), {:remove_call, call_identifier, reason})
  end

  @doc """
  Called when we receive notification that a conference has ended.

  This will clear the conference and hang up any pending call leg.
  This is done because if the conference has ended then there is no way to
  salvage it and there is no path for reconnecting to it.
  """
  @spec remove_conference(ContactCentre.Conferencing.Identifier.t) :: :ok
  def remove_conference(conference_identifier) do
    GenServer.cast(via_tuple(conference_identifier), {:remove_conference})
  end

  @doc """
  Called when we receive notification that a participant has left the conference.

  Depending on who is remaining in the conference, the remaining call legs may
  be hung up and the conference cleared. If there are any participants
  (including pending calls), then the conference will carry on (even if
  the chair has left). The reasoning behind this is to allow the chairperson to reconnect
  after becoming disconnected from the conference. If, however, it is just the
  chairperson remaining in the conference then their call leg will be hung up and the
  conference cleared.
  """
  @spec acknowledge_call_left(ContactCentre.Conferencing.Identifier.t, String.t) :: :ok
  def acknowledge_call_left(conference_identifier, providers_call_identifier) do
    GenServer.cast(via_tuple(conference_identifier), {:remove_call, providers_call_identifier, nil})
  end

  @doc """
  Called when we receive notification that a participant has joined the conference.

  If the chairperson has not yet been joined to the conference, this updates the
  call leg details for the chairperson on the conference and will then initiate the
  participant's call.
  """
  @spec acknowledge_call_joined(ContactCentre.Conferencing.Identifier.t, String.t, String.t) :: :ok
  def acknowledge_call_joined(conference_identifier, providers_identifier, providers_call_identifier) do
    GenServer.cast(via_tuple(conference_identifier), {:acknowledge_call_joined, providers_identifier, providers_call_identifier})
  end

  # Server

  def handle_cast({:add_participant, destination}, conference) do
    conference = add_participant(conference, destination)
    Events.publish(%Events.ConferenceUpdated{conference: conference})
    {:noreply, conference}
  end

  def handle_cast({:acknowledge_call_joined, providers_identifier, providers_call_identifier}, conference) do
    with_call(conference, providers_call_identifier, fn (call) ->
      {:ok, conference} = ContactCentre.Conferencing.Conference.set_providers_identifier(conference, providers_identifier)
      if ContactCentre.Conferencing.Conference.chairpersons_call?(conference, call.identifier) do
        call_pending_participants(conference)
      end
      Events.publish(%Events.ConferenceUpdated{conference: conference})
      {:noreply, conference}
    end)
  end

  def handle_cast({:remove_call, call_identifier, reason}, conference) do
    with_call(conference, call_identifier, fn (call) ->
      conference = conference
      |> ContactCentre.Conferencing.Conference.remove_call(call)
      |> clear_pointless_conference()

      Events.publish(%Events.ConferenceUpdated{conference: conference, reason: reason})
      if ContactCentre.Conferencing.Conference.empty?(conference) do
        handle_cast({:remove_conference}, conference)
      else
        {:noreply, conference}
      end
    end)
  end

  def handle_cast({:hangup_call, call_identifier}, conference) do
    with_call(conference, call_identifier, fn (call) ->
      conference = conference
      |> request_to_hangup_or_remove_call(call)
      Events.publish(%Events.ConferenceUpdated{conference: conference})
      {:noreply, conference}
    end)
  end

  def handle_cast({:update_status_of_call, call_identifier, providers_call_identifier, call_status, sequence_number}, conference) do
    with_call(conference, call_identifier, fn (call) ->
      with {:ok, conference, call} <- ContactCentre.Conferencing.Conference.set_providers_identifier_on_call(conference, call, providers_call_identifier),
      {:ok, conference, _} <- ContactCentre.Conferencing.Conference.update_status_of_call(conference, call, call_status, sequence_number) do
        Events.publish(%Events.ConferenceUpdated{conference: conference})
        {:noreply, conference}
      else
        _ ->
          {:noreply, conference}
      end
    end)
  end

  def handle_cast({:remove_conference}, conference) do
    conference = hangup_requested_calls(conference)
    Events.publish(%Events.ConferenceDeleted{conference: conference})
    {:stop, :normal, conference}
  end

  # Internals

  @spec initiate_conference(String.t, String.t) :: ContactCentre.Conferencing.Conference.t
  defp initiate_conference(chairperson, destination) do
    conference = ContactCentre.Conferencing.Conference.new(chairperson, destination)
    chairpersons_call = ContactCentre.Conferencing.Conference.chairpersons_call(conference)
    request_call(chairpersons_call, conference)
  end

  @spec add_participant(ContactCentre.Conferencing.Conference.t, String.t) :: ContactCentre.Conferencing.Conference.t
  defp add_participant(conference, destination) do
    conference
    |> ContactCentre.Conferencing.Conference.add_call(destination)
    |> call_pending_participants()
  end

  @spec clear_pointless_conference(ContactCentre.Conferencing.Conference.t) :: ContactCentre.Conferencing.Conference.t
  defp clear_pointless_conference(conference) do
    cond do
      ContactCentre.Conferencing.Conference.chairperson_is_alone?(conference) ->
        chairpersons_call = ContactCentre.Conferencing.Conference.chairpersons_call(conference)
        request_to_hangup_or_remove_call(conference, chairpersons_call)
      Enum.empty?(ContactCentre.Conferencing.Conference.requested_calls(conference)) ->
        Enum.reduce(ContactCentre.Conferencing.Conference.pending_calls(conference), conference, fn (call, conference) ->
          request_to_hangup_or_remove_call(conference, call)
        end)
      true ->
        conference
      end
  end

  @spec hangup_requested_calls(ContactCentre.Conferencing.Conference.t) :: ContactCentre.Conferencing.Conference.t
  defp hangup_requested_calls(conference) do
    conference
    |> ContactCentre.Conferencing.Conference.requested_calls()
    |> Enum.reduce(conference, fn (call, conference) ->
      request_to_hangup_or_remove_call(conference, call)
    end)
  end

  @spec request_to_hangup_or_remove_call(ContactCentre.Conferencing.Conference.t, ContactCentre.Conferencing.Call.t) :: ContactCentre.Conferencing.Conference.t
  def request_to_hangup_or_remove_call(conference, call) do
    cond do
      ContactCentre.Conferencing.Call.in_conference?(call) ->
        Events.publish(%Events.RemoveRequested{
              conference: conference.identifier,
              providers_identifier: conference.providers_identifier,
              call: call.identifier,
              providers_call_identifier: call.providers_identifier})
        conference
      ContactCentre.Conferencing.Call.requested?(call) ->
        Events.publish(%Events.HangupRequested{
              conference: conference.identifier,
              call: call.identifier,
              providers_call_identifier: call.providers_identifier})
        conference
      true ->
        ContactCentre.Conferencing.Conference.remove_call(conference, call)
    end
  end

  @spec call_pending_participants(ContactCentre.Conferencing.Conference.t) :: ContactCentre.Conferencing.Conference.t
  defp call_pending_participants(conference) do
    conference
    |> ContactCentre.Conferencing.Conference.pending_calls()
    |> Enum.reduce(conference, fn (call, conference) ->
      request_call(call, conference)
    end)
  end

  @spec request_call(ContactCentre.Conferencing.Call.t, ContactCentre.Conferencing.Conference.t) :: ContactCentre.Conferencing.Conference.t
  defp request_call(call, conference) do
    Events.publish(%Events.CallRequested{
          destination: call.destination,
          conference: conference.identifier,
          call: call.identifier})
    conference
  end

  @spec with_call(ContactCentre.Conferencing.Conference.t, ContactCentre.Conferencing.Identifier.t | String.t, ((ContactCentre.Conferencing.Call.t) -> {:noreply, ContactCentre.Conferencing.Conference.t})) :: {:noreply, ContactCentre.Conferencing.Conference.t}
  defp with_call(conference, call_identifier, block) do
    case ContactCentre.Conferencing.Conference.search_for_call(conference, call_identifier) do
      nil ->
        {:noreply, conference}
      call ->
        block.(call)
    end
  end

  @spec via_tuple(ContactCentre.Conferencing.Identifier.t) :: any
  defp via_tuple(conference_identifier), do: {:via, Registry, {ContactCentre.Conferencing.Registry, conference_identifier}}
end
