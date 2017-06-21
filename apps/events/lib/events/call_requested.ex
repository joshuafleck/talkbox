defmodule Events.CallRequested do
  @moduledoc """
  The system has requested that a call be made
  """
  @enforce_keys [:destination, :conference, :call]
  defstruct [
    destination: nil,
    conference: nil,
    call: nil
  ]

  @typedoc """
  Contains the internal identifiers of the call and
  conference as well as the destination for the call.
  """
  @type t :: %__MODULE__{
    destination: String.t,
    conference: String.t,
    call: String.t
  }
end
