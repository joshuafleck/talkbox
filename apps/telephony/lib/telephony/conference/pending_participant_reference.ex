defmodule Telephony.Conference.PendingParticipantReference do
  @moduledoc """
  A reference to a conference and its pending participant's identifier.
  This can be used to pass a reference to a conference and its pending participant
  between applications before the pending participant's call is answered.
  """
  @enforce_keys [:identifier, :chair, :pending_participant_identifier]
  defstruct [
    identifier: nil,
    chair: nil,
    pending_participant_identifier: nil
  ]

  @typedoc """
  A reference to a conference and its pending participant's identifier.
  Fields:
    * `identifier` - Our internally-generated conference identifier
    * `chair` - The name of the conference chairperson
    * `pending_participant_identifier` - The participant's name (when calling a client by name) or telephone number
  """
  @type t :: %__MODULE__{
    identifier: String.t,
    chair: String.t,
    pending_participant_identifier: String.t
  }
end
