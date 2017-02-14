defmodule Telephony.Conference.Leg do
  @moduledoc """
  The representation of a conference participant or chairperson's call leg.
  It has an `identifier`, which will be either the chairperson's name
  or the participant's name/number. When the participant/chair is dialled,
  then the `call_sid` will be populated with the sid of their call leg.
  The `call_status` stores the status of their call, e.g. `ringing`, and is
  represented as a tuple of the name of the status and the sequence number
  of the status (so we can determine if status updates are arriving in
  sequential order).
  """
  @enforce_keys [:identifier]
  defstruct [
    identifier: nil,
    call_sid: nil,
    call_status: {nil, -1}
  ]

  @typedoc """
  The representation of a conference participant or chairperson's call leg.
  Fields:
    * `identifier` - The chairperson's name or the participant's name (when calling a client by name) or telephone number
    * `call_sid` - The sid of the call provided by the telephony provider upon initiating the call, which we use for manipulating the call state
    * `call_status` - The name of the most recent call status and the sequence in which the call status arrived
  """
  @type t :: %__MODULE__{
    identifier: String.t,
    call_sid: String.t | nil,
    call_status: {String.t | nil, integer}
  }
end
