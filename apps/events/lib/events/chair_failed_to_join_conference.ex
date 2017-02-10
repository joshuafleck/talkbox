defmodule Events.ChairFailedToJoinConference do
  @moduledoc """
  The chairperson has failed to join their conference. Published when
  we are notified that the chairperson's call leg could not be connected.
  """
  @derive [Poison.Encoder]
  @enforce_keys [:conference, :chair, :call_sid, :reason]
  defstruct [
    conference: nil,
    chair: nil,
    call_sid: nil,
    reason: nil
  ]

  @typedoc """
  Provides a reference to the conference and information on why the call leg failed.
  Fields:
    * `conference` - The conference identifier generated when a conference is requested
    * `chair` - The name of the conference chairperson
    * `call_sid` - The call sid of the chair's call leg provided by the telephony provider
    * `reason` - The reason why the call leg could not be connected (a call status)
  """
  @type t :: %__MODULE__{
    conference: String.t,
    chair: String.t,
    call_sid: String.t,
    reason: String.t
  }
end
