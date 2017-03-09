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

  defimpl Routing, for: Events.ChairFailedToJoinConference do
    @spec routing(Events.ChairFailedToJoinConference.t) :: any
    def routing(event) do
      # TODO: think about if these need to cater for the unhappy path
      Telephony.remove_conference(
        %Telephony.Conference.Reference{
          chair: event.chair,
          identifier: event.conference})
      Router.Web.broadcast(event.chair, "Failed to start call: Telephony provider was unable to connect to your browser", nil)
    end
  end

  defimpl Routing, for: Events.PendingParticipantFailedToJoinConference do
    @spec routing(Events.PendingParticipantFailedToJoinConference.t) :: any
    def routing(event) do
      conference = Telephony.remove_pending_participant(
        %Telephony.Conference.PendingParticipantReference{
          chair: event.chair,
          identifier: event.conference,
          pending_participant_identifier: event.pending_participant})
      Router.Web.broadcast(event.chair, "Failed to reach #{event.pending_participant}", conference)
    end
  end

  defimpl Routing, for: Events.PendingParticipantCallStatusChanged do
    @spec routing(Events.PendingParticipantCallStatusChanged.t) :: any
    def routing(event) do
      conference = Telephony.update_call_status_of_pending_participant(
        %Telephony.Conference.PendingParticipantReference{
          chair: event.chair,
          identifier: event.conference,
          pending_participant_identifier: event.pending_participant},
        event.call_status,
        event.sequence_number)
      Router.Web.broadcast(event.chair, "Call status changed for #{event.pending_participant}", conference)
    end
  end

  defimpl Routing, for: Events.ParticipantJoinedConference do
    @spec routing(Events.ParticipantJoinedConference.t) :: any
    def routing(event) do
      result = Telephony.call_or_promote_pending_participant(
        %Telephony.Conference.ParticipantReference{
          chair: event.chair,
          identifier: event.conference,
          conference_sid: event.conference_sid,
          participant_call_sid: event.call_sid})
      case result do
        {:ok, conference} ->
          Router.Web.broadcast(event.chair, "Someone joined", conference)
        {:error, message, conference} ->
          Router.Web.broadcast(event.chair, "Failed to join participant to conference due to: #{message}", conference)
      end
    end
  end

  defimpl Routing, for: Events.ParticipantLeftConference do
    @spec routing(Events.ParticipantLeftConference.t) :: any
    def routing(event) do
      conference = Telephony.remove_chair_or_participant(
        %Telephony.Conference.ParticipantReference{
          chair: event.chair,
          identifier: event.conference,
          conference_sid: event.conference_sid,
          participant_call_sid: event.call_sid})
      case conference do
        nil ->
          nil
        conference ->
          Router.Web.broadcast(event.chair, "Someone left", conference)
      end
    end
  end

  defimpl Routing, for: Events.ConferenceEnded do
    @spec routing(Events.ConferenceEnded.t) :: any
    def routing(event) do
      Telephony.remove_conference(
        %Telephony.Conference.Reference{
          chair: event.chair,
          identifier: event.conference})
      Router.Web.broadcast(event.chair, "Call ended", nil)
    end
  end

  defimpl Routing, for: Events.ChairRequestsToCancelPendingParticipant do
    @spec routing(Events.ChairRequestsToCancelPendingParticipant.t) :: any
    def routing(event) do
      Telephony.hangup_pending_participant(
        %Telephony.Conference.PendingParticipantReference{
          chair: event.chair,
          identifier: event.conference,
          pending_participant_identifier: event.pending_participant})
    end
  end

  defimpl Routing, for: Events.ChairRequestsToHangupParticipant do
    @spec routing(Events.ChairRequestsToHangupParticipant.t) :: any
    def routing(event) do
      Telephony.hangup_participant(
        %Telephony.Conference.ParticipantReference{
          chair: event.chair,
          identifier: event.conference,
          participant_call_sid: event.call_sid,
          conference_sid: nil})
    end
  end
end
