defmodule Events.PendingParticipantFailedToJoinConference do
  @moduledoc """
  The pending participant's call leg could not be joined to the conference.
  Published when we are notified that the pending participants's call leg
  could not be connected.
  """
  @derive [Poison.Encoder]
  @enforce_keys [:conference, :chair, :call_sid, :pending_participant, :reason]
  defstruct [
    conference: nil,
    chair: nil,
    call_sid: nil,
    pending_participant: nil,
    reason: nil
  ]

  @typedoc """
  Provides a reference to the conference and information on why the call leg failed.
  Fields:
    * `conference` - The conference identifier generated when a conference is requested
    * `chair` - The name of the conference chairperson
    * `call_sid` - The call sid of the participant's call leg provided by the telephony provider
    * `pending_participant` - The pending participant's name (when calling a client by name) or telephone number
    * `reason` - The reason why the call leg could not be connected (a call status)
    """
  @type t :: %__MODULE__{
    conference: String.t,
    chair: String.t,
    call_sid: String.t,
    pending_participant: String.t,
    reason: String.t
  }
end
