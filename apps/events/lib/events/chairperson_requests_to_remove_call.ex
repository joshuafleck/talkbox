defmodule Events.ChairpersonRequestsToRemoveCall do
  @moduledoc """
  A chair has requested to remove a call from the conference.
  """
  @enforce_keys [:conference, :call]
  defstruct [
    conference: nil,
    call: nil
  ]

  @typedoc """
  Provides a reference to the conference and the call
  Fields:
  * `conference` - The conference identifier generated when a conference is requested
  * `call` - The call identifier generated when a call is requested
  """
  @type t :: %__MODULE__{
    conference: String.t,
    call: String.t
  }
end
