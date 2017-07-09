defmodule Events do
  @moduledoc """
  This module provides the ability for applications to publish events
  that can then be consumed and acted upon asyncronously. Each type of
  event will have its structure defined in a module within this app
  such that the producers and consumers of these events can include
  this application to ensure event definitions are the same for both
  the producers and consumers.
  """

  @typedoc """
  All of the possible events
  """
  @type t :: CallFailedToJoinConference.t
  | CallJoinedConference.t
  | CallLeftConference.t
  | CallRequested.t
  | CallRequestedFailed.t
  | CallStatusChanged.t
  | ChairpersonRequestsToRemoveCall.t
  | ConferenceEnded.t
  | HangupRequested.t
  | RemoveRequested.t
  | UserRequestsCall.t

  @doc """
  Subscribe to events of a given event type.

  Subscribers should run a `GenServer` and implement
  a customised `Events.Handler` behaviour for any
  events to which they are subscribed. Events will be
  sent as a `:broadcast` message and can be handled as
  follows:

  ```
  def handle_info({:broadcast, event}, state) do
  Events.Handler.handle(event)
  {:noreply, state}
  end
  ```

  ## Examples

  iex(1)> Events.subscribe(UserRequestsCall)
  :ok
  """
  @spec subscribe(atom) :: :ok
  def subscribe(topic) do
    {:ok, _} = Registry.register(Events.Registry, topic, [])
    :ok
  end

  @doc """
  Publish an event that will be routed to all
  subscribers subscribed to that event type.

  ## Examples

  iex(2)> Events.publish(%Events.UserRequestsCall{user: "user", callee: "callee", conference: nil})
  :ok
  """
  @spec publish(Events.t) :: :ok
  def publish(event) do
    Events.Persistence.write(event)
    Registry.dispatch(Events.Registry, event.__struct__, fn entries ->
      for {pid, _} <- entries, do: send(pid, {:broadcast, event})
    end)
  end
end
