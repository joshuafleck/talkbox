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

  defimpl Routing, for: Events.ChairJoiningConference do
    def routing(event) do
      Telephony.call_pending_participant(chair: event.chair, conference: event.conference)
    end
  end

  defimpl Routing, for: Events.UserRequestsCall do
    def routing(event) do
      Telephony.initiate_conference(chair: event.user, participant: event.callee)
    end
  end
end
