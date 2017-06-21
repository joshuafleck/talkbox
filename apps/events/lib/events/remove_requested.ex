defmodule Events.RemoveRequested do
  @moduledoc """
  A call has been requested to be removed from a conference.
  """
  @enforce_keys [:conference, :providers_identifier, :call, :providers_call_identifier]
  defstruct [
    conference: nil,
    providers_identifier: nil,
    call: nil,
    providers_call_identifier: nil
  ]

  @typedoc """
  Contains the internal and provider's identifiers for the
  conference and the call that is to be removed.
  """
  @type t :: %__MODULE__{
    conference: String.t,
    providers_identifier: String.t,
    call: String.t,
    providers_call_identifier: String.t
  }
end
