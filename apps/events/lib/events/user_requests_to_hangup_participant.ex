defmodule Events.UserRequestsToHangupParticipant do
  @moduledoc """
  TODO
  """
  @enforce_keys [:conference, :chair, :call_sid]
  defstruct [
    conference: nil,
    chair: nil,
    call_sid: nil
  ]

  @typedoc """
  Provides a reference to the conference and the participant's call leg
  Fields:
    * `conference` - The conference identifier generated when a conference is requested
    * `chair` - The name of the conference chairperson
    * `call_sid` - The call sid of the participant's (or chair's) call leg provided by the telephony provider
  """
  @type t :: %__MODULE__{
    conference: String.t,
    chair: String.t,
    call_sid: String.t
  }
end
