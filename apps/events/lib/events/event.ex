defmodule Events.Event do
  @moduledoc """
  Provides a means for sending messages between applications asyncronously.
  This struct acts as a generic wrapper around a more detailed event, which
  will typically consist of an actor, verb and object, e.g.
  `participant_joined_conference`. The responsibility of this module is to
  store the more detailed event along with some metadata about the event.
  """
  defstruct [
    created_at: nil,
    type: nil,
    payload: nil
  ]

  @typedoc """
  An event consisting of metadata and a more specific event payload.
  Fields:
    * `created_at` - The time at which the event was created (UTC)
    * `type` - The name of the specific event module
    * `payload` - The specific event data
  """
  @type t :: %__MODULE__{
    created_at: String.t,
    type: String.t,
    payload: struct()
  }
end
