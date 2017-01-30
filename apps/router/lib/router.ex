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

  # TODO: can this same functionality be achieved using the [Registry](https://hexdocs.pm/elixir/master/Registry.html#module-using-as-a-pubsub)?
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
      # TODO: notify of joining in ui app
    end
  end

  defimpl Routing, for: Events.ParticipantLeftConference do
    def routing(event) do
      Telephony.remove_chair_or_participant(
        chair: event.chair,
        conference: event.conference,
        call_sid: event.call_sid)
      # TODO: notify of leaving in ui app
    end
  end

  defimpl Routing, for: Events.ConferenceEnded do
    def routing(event) do
      # TODO: not sure if this is strictly necessary as &remove_chair_or_participant takes care of removing the conference already,
      #       Also, we don't want to remove the conference before we get a chance to end any remaining call legs
      # Telephony.remove_conference(
      #   chair: event.chair,
      #   conference: event.conference)
      # TODO: notify of ending in ui app
    end
  end
end
