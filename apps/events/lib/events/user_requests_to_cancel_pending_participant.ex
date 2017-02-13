defmodule Events.UserRequestsToCancelPendingParticipant do
  @moduledoc """
  A user has requested to cancel a dial to a pending participant.
  """
  @enforce_keys [:conference, :chair, :pending_participant]
  defstruct [
    conference: nil,
    chair: nil,
    pending_participant: nil
  ]

  @typedoc """
  Provides a reference to the conference and the participant's call leg
  Fields:
    * `conference` - The conference identifier generated when a conference is requested
    * `chair` - The name of the conference chairperson
    * `pending_participant` - The pending participant's name (when calling a client by name) or telephone number
  """
  @type t :: %__MODULE__{
    conference: String.t,
    chair: String.t,
    pending_participant: String.t
  }
end
