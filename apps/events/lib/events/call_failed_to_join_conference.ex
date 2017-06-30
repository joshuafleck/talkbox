defmodule Events.CallFailedToJoinConference do
  @moduledoc """
  The call leg could not be joined to the conference.
  Published when we are notified that the call leg
  could not be connected.
  """
  @enforce_keys [:conference, :call, :providers_call_identifier, :reason]
  defstruct [
    conference: nil,
    call: nil,
    providers_call_identifier: nil,
    reason: nil
  ]

  @typedoc """
  Provides a reference to the conference and information on why the call leg failed.
  Fields:
    * `conference` - The conference identifier generated when a conference is requested
    * `call` - The call identifier generated with a call is requested
    * `providers_call_identifier` - The identifier of the participant's call leg provided by the telephony provider
    * `reason` - The reason why the call leg could not be connected (a call status)
    """
  @type t :: %__MODULE__{
    conference: String.t,
    call: String.t,
    providers_call_identifier: String.t,
    reason: String.t
  }
end
