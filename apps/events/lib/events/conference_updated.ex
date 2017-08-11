defmodule Events.ConferenceUpdated do
  @moduledoc """
  A conference has been updated - this is an internal event not
  triggered by any telephony provider but used to indicate that
  the conference state in the system has changed.
  """
  @enforce_keys [:conference]
  defstruct [
    conference: nil,
    reason: nil
  ]
  @typedoc """
  Contains the updated conference state and an optional
  reason as to why the state has changed.
  """
  @type t :: %__MODULE__{
    conference: struct,
    reason: String.t | nil
  }
end
