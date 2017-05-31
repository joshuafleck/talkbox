defmodule Router do
  @moduledoc """
  Responsible for consuming events published by any users of the `Events`
  application and translating these events into a series of actions against
  one or more applications.
  """

  defprotocol Routing do
    @doc """
    Given an event will apply behaviour specific to that event
    """
    def routing(event)
  end

  defimpl Routing, for: Events.UserRequestsCall do
    @spec routing(Events.UserRequestsCall.t) :: any
    def routing(event) do
      case Telephony.add_participant_or_initiate_conference(event.user, event.callee) do
        {:ok, conference} ->
          Router.Web.broadcast(event.user, "Starting call", conference)
        {:error, message, conference} ->
          Router.Web.broadcast(event.user, "Error starting call: #{message}", conference)
      end
    end
  end

  defimpl Routing, for: Events.CallFailedToJoinConference do
    @spec routing(Events.CallFailedToJoinConference.t) :: any
    def routing(event) do
      conference = Telephony.remove_call(
        event.conference,
        event.call)
      Router.Web.broadcast("Josh", "Failed to reach #{event.call}", conference)
    end
  end

  defimpl Routing, for: Events.CallStatusChanged do
    @spec routing(Events.CallStatusChanged.t) :: any
    def routing(event) do
      conference = Telephony.update_status_of_call(
        event.conference,
        event.call,
        event.providers_call_identifier,
        event.status,
        event.sequence_number)
      Router.Web.broadcast("Josh", "Call status changed for #{event.call}", conference)
    end
  end

  defimpl Routing, for: Events.CallJoinedConference do
    @spec routing(Events.CallJoinedConference.t) :: any
    def routing(event) do
      result = Telephony.acknowledge_call_joined(
        event.conference,
        event.providers_identifier,
        event.providers_call_identifier)
      case result do
        {:ok, conference} ->
          Router.Web.broadcast("Josh", "Someone joined", conference)
        {:error, message, conference} ->
          Router.Web.broadcast("Josh", "Failed to join participant to conference due to: #{message}", conference)
      end
    end
  end

  defimpl Routing, for: Events.CallLeftConference do
    @spec routing(Events.CallLeftConference.t) :: any
    def routing(event) do
      conference = Telephony.acknowledge_call_left(
        event.conference,
        event.providers_call_identifier)
      case conference do
        nil ->
          nil
        conference ->
          Router.Web.broadcast("Josh", "Someone left", conference)
      end
    end
  end

  defimpl Routing, for: Events.ConferenceEnded do
    @spec routing(Events.ConferenceEnded.t) :: any
    def routing(event) do
      Telephony.remove_conference(
        event.conference)
      Router.Web.broadcast("Josh", "Call ended", nil)
    end
  end

  defimpl Routing, for: Events.ChairpersonRequestsToRemoveCall do
    @spec routing(Events.ChairpersonRequestsToRemoveCall.t) :: any
    def routing(event) do
      Telephony.hangup_call(
        event.conference,
        event.call)
    end
  end
end
