defmodule Router do
  @moduledoc """
  Documentation for Router.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Router.hello
      :world

  """
  def hello do
    :world
  end

  defprotocol Routing do
    @doc "TODO"
    def routing(event)
  end

  defimpl Routing, for: Events.UserRequestsCall do
    def routing(event) do
      Telephony.initiate_conference(
        chair: event.user, participant: event.callee)
    end
  end

  defimpl Routing, for: Events.ChairFailedToJoinConference do
    def routing(event) do
      # TODO: What if they are attempting to rejoin an ongoing conference (it's probably okay, though)?
      Telephony.remove_conference(
        chair: event.chair, conference: event.conference)
      # TODO: notify of failed call in ui app
    end
  end

  defimpl Routing, for: Events.PendingParticipantFailedToJoinConference do
    def routing(event) do
      Telephony.remove_pending_participant(
        chair: event.chair,
        conference: event.conference,
        pending_participant: event.pending_participant)
      # TODO: notify of failed call in ui app
    end
  end

  defimpl Routing, for: Events.PendingParticipantCallStatusChanged do
    def routing(event) do
      Telephony.update_call_status_of_pending_participant(
        chair: event.chair,
        conference: event.conference,
        pending_participant: event.pending_participant,
        call_status: event.call_status,
        sequence_number: event.sequence_number)
      # TODO: notify of status change for call in ui app
    end
  end

  defimpl Routing, for: Events.ParticipantJoinedConference do
    def routing(event) do
      Telephony.call_or_promote_pending_participant(
        chair: event.chair,
        conference: event.conference,
        call_sid: event.call_sid,
        conference_sid: event.conference_sid)
      # TODO: notify of joining in ui app - here or on conference update??
    end
  end

  defimpl Routing, for: Events.ParticipantLeftConference do
    def routing(event) do
      # TODO
      # Telephony.call_or_promote_pending_participant(
      #   chair: event.chair,
      #   conference: event.conference,
      #   call_sid: event.call_sid,
      #   conference_sid: event.conference_sid)
      # TODO: notify of joining in ui app - here or on conference update??
    end
  end

  defimpl Routing, for: Events.ConferenceEnded do
    def routing(event) do
      # TODO
      # Telephony.call_or_promote_pending_participant(
      #   chair: event.chair,
      #   conference: event.conference,
      #   conference_sid: event.conference_sid)
      # TODO: notify of joining in ui app - here or on conference update??
    end
  end
end
