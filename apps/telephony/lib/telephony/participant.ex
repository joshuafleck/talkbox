defmodule Telephony.Participant do

  @enforce_keys [:identifier]
  defstruct [
    identifier: nil,
    call_sid: nil,
    participation_status: nil,
    call_status: nil
  ]

  @type t :: %__MODULE__{
    identifier: String.t,
    call_sid: String.t,
    participation_status: map,
    call_status: map
  }
end
