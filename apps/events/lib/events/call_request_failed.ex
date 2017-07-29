defmodule Events.CallRequestFailed do
  @moduledoc """
  The request to make a call has failed
  """
  @enforce_keys [:conference, :call]
  defstruct [
    conference: nil,
    call: nil,
    reason: nil
  ]

  @typedoc """
  Contains the internal identifiers of the call and
  conference.
  """
  @type t :: %__MODULE__{
    conference: String.t,
    call: String.t,
    reason: String.t
  }
end
