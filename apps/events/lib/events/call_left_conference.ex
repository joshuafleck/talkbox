defmodule Events.CallLeftConference do
  @moduledoc """
  A call has left the conference. Published when we are
  notified by the telephony provider that a call leg has left
  a conference. This could be referring to the chair or pending
  participant's call leg, as the telephony provider does not provide this
  distinction.
  """
  @enforce_keys [:conference, :providers_identifier, :providers_call_identifier]
  defstruct [
    conference: nil,
    providers_identifier: nil,
    providers_call_identifier: nil
  ]

  @typedoc """
  Provides a reference to the conference and the participant's call leg
  Fields:
  * `conference` - The conference identifier generated when a conference is requested
  * `providers_identifier` - The identifier of the conference provided by the telephony provider
  * `providers_call_identifier` - The call identifier of the call leg provided by the telephony provider
  """
  @type t :: %__MODULE__{
    conference: String.t,
    providers_identifier: String.t,
    providers_call_identifier: String.t
  }
end
