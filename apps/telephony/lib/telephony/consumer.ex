defmodule Telephony.Consumer do
  use GenServer
  @moduledoc """
  Responsible for consuming events published by any users of the `Events`
  application and translating these events into a series of actions against
  one or more applications.
  """

  def init(_) do
     Events.subscribe(Events.CallFailedToJoinConference)
     Events.subscribe(Events.CallJoinedConference)
     Events.subscribe(Events.CallLeftConference)
     Events.subscribe(Events.CallStatusChanged)
     Events.subscribe(Events.ChairpersonRequestsToRemoveCall)
     Events.subscribe(Events.ConferenceEnded)
     Events.subscribe(Events.UserRequestsCall)
     {:ok, nil}
  end

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def handle_info({:broadcast, event}, state) do
    Events.Handler.handle(event)
    {:noreply, state}
  end

  defimpl Events.Handler, for: Events.UserRequestsCall do
    @spec handle(Events.UserRequestsCall.t) :: any
    def handle(event) do
      case Telephony.add_participant_or_initiate_conference(event.user, event.callee, event.conference) do
        {:ok, conference} ->
          Telephony.Web.broadcast_conference_start(event.user, "Starting call", conference)
        {:error, message, conference} ->
          Telephony.Web.broadcast_conference_start(event.user, "Error starting call: #{message}", conference)
      end
    end
  end

  defimpl Events.Handler, for: Events.CallFailedToJoinConference do
    @spec handle(Events.CallFailedToJoinConference.t) :: any
    def handle(event) do
      conference = Telephony.remove_call(
        event.conference,
        event.call)
      Telephony.Web.broadcast_conference_changed("Failed to reach #{event.call}", conference)
    end
  end

  defimpl Events.Handler, for: Events.CallStatusChanged do
    @spec handle(Events.CallStatusChanged.t) :: any
    def handle(event) do
      conference = Telephony.update_status_of_call(
        event.conference,
        event.call,
        event.providers_call_identifier,
        event.status,
        event.sequence_number)
      Telephony.Web.broadcast_conference_changed("Call status changed for #{event.call}", conference)
    end
  end

  defimpl Events.Handler, for: Events.CallJoinedConference do
    @spec handle(Events.CallJoinedConference.t) :: any
    def handle(event) do
      result = Telephony.acknowledge_call_joined(
        event.conference,
        event.providers_identifier,
        event.providers_call_identifier)
      case result do
        {:ok, conference} ->
          Telephony.Web.broadcast_conference_changed("Someone joined", conference)
        {:error, message, conference} ->
          Telephony.Web.broadcast_conference_changed("Failed to join participant to conference due to: #{message}", conference)
      end
    end
  end

  defimpl Events.Handler, for: Events.CallLeftConference do
    @spec handle(Events.CallLeftConference.t) :: any
    def handle(event) do
      conference = Telephony.acknowledge_call_left(
        event.conference,
        event.providers_call_identifier)
      case conference do
        nil ->
          nil
        conference ->
          Telephony.Web.broadcast_conference_changed("Someone left", conference)
      end
    end
  end

  defimpl Events.Handler, for: Events.ConferenceEnded do
    @spec handle(Events.ConferenceEnded.t) :: any
    def handle(event) do
      conference = Telephony.remove_conference(
        event.conference)
      Telephony.Web.broadcast_conference_end("Call ended", conference)
    end
  end

  defimpl Events.Handler, for: Events.ChairpersonRequestsToRemoveCall do
    @spec handle(Events.ChairpersonRequestsToRemoveCall.t) :: any
    def handle(event) do
      Telephony.hangup_call(
        event.conference,
        event.call)
    end
  end
end
