defmodule Telephony.Conference.ParticipantReference do
  @moduledoc """
  A reference to a conference and one of its participant's (or the chairperson's)
  call leg. This will typically only be used to reference a conference that
  has already started, as it requires a conference sid and participant call sid
  to be present. This can be used to pass a reference to a particular leg of the
  conference between applications.
  """
  @enforce_keys [:identifier, :chair, :conference_sid, :participant_call_sid]
  defstruct [
    identifier: nil,
    chair: nil,
    conference_sid: nil,
    participant_call_sid: nil
  ]

  @typedoc """
  A reference to a conference and one of its participant's (or the chairperson's)
  call leg.
  Fields:
    * `identifier` - Our internally-generated conference identifier
    * `chair` - The name of the conference chairperson
    * `conference_sid` - The sid of the conference provided by the telephony provider upon starting the conference
    * `participant_call_sid` - The sid of the participant's call provided by the telephony provider
  """
  @type t :: %__MODULE__{
    identifier: String.t,
    chair: String.t,
    conference_sid: String.t,
    participant_call_sid: String.t
  }
end
