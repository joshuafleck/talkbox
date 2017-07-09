defmodule Events.Event do
  @moduledoc """
  Provides the ability to serialize and deserialize
  events. Accomplished by wrapping one of the more
  specific events in a structure that contains
  metadata that can be used to re-instantiate when
  deserializing.
  """
  @enforce_keys [:name, :data]
  defstruct [
    name: nil,
    data: nil
  ]

  @typedoc """
  Represents an event in a serializable format.
  Fields:
    * `name` - The name of the event, i.e. what type of event is it
    * `data` - The data contained within the event
  """
  @type t :: %__MODULE__{
    name: String.t,
    data: String.t
  }

  @doc ~S"""
  Serializes the event as JSON

  ## Examples

  iex(25)> Events.Event.serialize(%Events.UserRequestsCall{callee: "amy", user: "josh", conference: nil})
  "{\"name\":\"Elixir.Events.UserRequestsCall\",\"data\":\"{\\\"user\\\":\\\"josh\\\",\\\"conference\\\":null,\\\"callee\\\":\\\"amy\\\"}\"}"
  """
  @spec serialize(Events.t) :: String.t
  def serialize(event) do
    %name{} = event
    data = Poison.encode!(event)
    %__MODULE__{
      name: name,
      data: data
    } |> Poison.encode!
  end

  @doc ~S"""
  Deserializes the event from JSON

  ## Examples

  iex(1)> Events.Event.deserialize("{\"name\":\"Elixir.Events.UserRequestsCall\",\"data\":\"{\\\"user\\\":\\\"josh\\\",\\\"conference\\\":null,\\\"callee\\\":\\\"amy\\\"}\"}")
  %Events.UserRequestsCall{callee: "amy", user: "josh", conference: nil}
  """
  @spec deserialize(String.t) :: Events.t
  def deserialize(raw) do
    event = Poison.decode!(raw, as: struct(__MODULE__))
    type = String.to_existing_atom(event.name)
    Poison.decode!(event.data, as: struct(type))
  end
end
