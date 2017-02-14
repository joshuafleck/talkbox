defmodule Events.ChairRequestsToAddParticipant do
  @moduledoc """
  A chairperson has requested to add a participant to the conference
  """
  @enforce_keys [:conference, :chair, :pending_participant]
  defstruct [
    conference: nil,
    chair: nil,
    pending_participant: nil
  ]

  @typedoc """
  Provides a reference to the conference and the participant's name/number
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
