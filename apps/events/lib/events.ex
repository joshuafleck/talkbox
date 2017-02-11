defmodule Events do
  @moduledoc """
  This module provides the ability for applications to publish events
  that can then be consumed and acted upon asyncronously. Each type of
  event will have its structure defined in a module within this app
  such that the producers and consumers of these events can include
  this application to ensure event definitions are the same for both
  the producers and consumers.

  Currently, events are published to an in-memory queue structure, but
  could be published to a third-party application like RabbitMQ to take
  advantage of topics, multiplexing, etc.
  """
  require Logger

  @doc """
  Publishes an event to the queue of events

  ## Example

  TODO
  """
  def publish(event) do
    Logger.debug "#{__MODULE__} publishing #{inspect(event)}"
    event
    |> Events.Queue.put
  end

  @doc """
  Consumes an event from the queue of events

  ## Example

  TODO
  """
  def consume do
    Events.Queue.pop
  end
end
