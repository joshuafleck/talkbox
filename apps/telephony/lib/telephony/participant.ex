defmodule Telephony.Participant do

  @enforce_keys [:identifier]
  defstruct [
    identifier: nil,
    call_sid: nil,
    call_status: {nil, -1}
  ]

  @type t :: %__MODULE__{
    identifier: String.t,
    call_sid: String.t,
    call_status: {String.t, non_neg_integer}
  }
end
