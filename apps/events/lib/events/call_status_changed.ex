defmodule Events.CallStatusChanged do
  @moduledoc """
  The call status of the call leg has changed.
  Published when we are notified by the telephony provider that the
  status of the call leg has been updated (e.g. from `queued` to `ringing`).
  Note that the telephony provider provides a sequence number along with these
  updates allowing us to determine if the updates have arrived to our server
  out of order.
  """
  @enforce_keys [:conference, :call, :providers_call_identifier, :status, :sequence_number]
  defstruct [
    conference: nil,
    call: nil,
    providers_call_identifier: nil,
    status: nil,
    sequence_number: nil
  ]

  @typedoc """
    * `conference` - The conference identifier generated when a conference is requested
    * `call` - The call identifier generated when a call is requested
    * `providers_call_identifier` - The identifier of the call leg provided by the telephony provider
    * `status` - The call status as provided by the telephony provider
    * `sequence_number` - A number provided by the telephony provider indicating the position of the update within a sequence of updates
  """
  @type t :: %__MODULE__{
    conference: String.t,
    call: String.t,
    providers_call_identifier: String.t,
    status: String.t,
    sequence_number: non_neg_integer
  }
end
