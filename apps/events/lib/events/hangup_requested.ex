defmodule Events.HangupRequested do
  @moduledoc """
  A call is requested to be hung up.
  """
  @enforce_keys [:conference, :call, :providers_call_identifier]
  defstruct [
    conference: nil,
    call: nil,
    providers_call_identifier: nil
  ]

  @typedoc """
  Contains the internal and provider's identifiers for the
  call that is to be removed and the internal identifier of
  the conference (for reference).
  """
  @type t :: %__MODULE__{
    conference: String.t,
    call: String.t,
    providers_call_identifier: String.t
  }
end
