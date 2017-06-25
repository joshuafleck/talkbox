defmodule ContactCentre.State.Call do
  @moduledoc """
  The representation of a conference participant or chairperson's call leg.
  """
  @enforce_keys [:identifier, :destination]
  defstruct [
    identifier: nil,
    destination: nil,
    providers_identifier: nil,
    status: {nil, -1}
  ]

  @typedoc """
  The representation of a conference participant or chairperson's call leg.
  Fields:
    * `identifier` - Internal identifier of the call
    * `destination` - The chairperson's name or the participant's name (when calling a client by name) or telephone number
    * `providers_identifier` - The identifier of the call provided by the telephony provider upon initiating the call, which we use for manipulating the call state
    * `status` - The name of the most recent call status and the sequence in which the call status arrived
  """
  @type t :: %__MODULE__{
    identifier: ContactCentre.State.Conference.internal_identifier,
    destination: String.t,
    providers_identifier: String.t | nil,
    status: {String.t | nil, integer}
  }
end
