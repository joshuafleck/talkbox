defmodule Events do
  @moduledoc """
  This module provides the ability for applications to publish events
  that can then be consumed and acted upon asyncronously. Each type of
  event will have its structure defined in a module within this app
  such that the producers and consumers of these events can include
  this application to ensure event definitions are the same for both
  the producers and consumers.
  """
  require Logger

  def publish(event) do
    event
    |> encode
    |> publish_to_rabbit("talkbox_routing") # TODO: use a proper routing key
  end

  def decode(event_json) do
    event_with_metadata = Poison.decode!(event_json, as: %Events.Event{})
    payload_type = String.to_existing_atom(event_with_metadata.type)
    Poison.decode!(event_with_metadata.payload, as: payload_type.__struct__)
  end

  defp encode(event) do
    event_with_metadata = %Events.Event{
      created_at: DateTime.utc_now,
      type: event.__struct__,
      payload: Poison.encode!(event)
    }
    event_with_metadata
    |> Poison.encode!
  end

  # TODO: properly manage connections, set headers and publishing options
  defp publish_to_rabbit(event_json, routing_key) do
    Logger.debug "#{__MODULE__} publishing #{event_json}"
    {:ok, conn} = AMQP.Connection.open
    {:ok, chan} = AMQP.Channel.open(conn)
    :ok = AMQP.Basic.publish(chan, "", routing_key, event_json, persistent: true, mandatory: true)
    AMQP.Connection.close(conn)
  end
end
