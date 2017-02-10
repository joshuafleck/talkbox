defmodule Events.ParticipantJoinedConference do
  @moduledoc """
  A participant (or chair) has joined the conference. Published when we are
  notified by the telephony provider that a call leg has joined
  a conference. This could be referring to the chair or pending
  participant's call leg, as the telephony provider does not provide this
  distinction.
  """
  @derive [Poison.Encoder]
  @enforce_keys [:conference, :chair, :call_sid, :conference_sid]
  defstruct [
    conference: nil,
    chair: nil,
    call_sid: nil,
    conference_sid: nil
  ]

  @typedoc """
  Provides a reference to the conference and the participant's call leg
  Fields:
    * `conference` - The conference identifier generated when a conference is requested
    * `chair` - The name of the conference chairperson
    * `call_sid` - The call sid of the participant's (or chair's) call leg provided by the telephony provider
    * `conference_sid` - The sid of the conference provided by the telephony provider
  """
  @type t :: %__MODULE__{
    conference: String.t,
    chair: String.t,
    call_sid: String.t,
    conference_sid: String.t
  }
end
