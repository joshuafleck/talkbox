defmodule Events.PendingParticipantCallStatusChanged do
  @moduledoc """
  The call status of the pending participant's call leg has changed.
  Published when we are notified by the telephony provider that the
  status of the participant's call leg has been updated (e.g. from `queued` to `ringing`).
  Note that the telephony provider provides a sequence number along with these
  updates allowing us to determine if the updates have arrived to our server
  out of order.
  """
  @enforce_keys [:conference, :chair, :call_sid, :pending_participant, :call_status, :sequence_number]
  defstruct [
    conference: nil,
    chair: nil,
    call_sid: nil,
    pending_participant: nil,
    call_status: nil,
    sequence_number: nil
  ]

  @typedoc """
    * `conference` - The conference identifier generated when a conference is requested
    * `chair` - The name of the conference chairperson
    * `call_sid` - The call sid of the chair's call leg provided by the telephony provider
    * `pending_participant` - The pending participant's name (when calling a client by name) or telephone number
    * `call_status` - The call status as provided by the telephony provider
    * `sequence_number` - A number provided by the telephony provider indicating the position of the update within a sequence of updates
  """
  @type t :: %__MODULE__{
    conference: String.t,
    chair: String.t,
    call_sid: String.t,
    pending_participant: String.t,
    call_status: String.t,
    sequence_number: non_neg_integer
  }
end
