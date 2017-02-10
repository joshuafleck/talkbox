defmodule Events.ConferenceEnded do
  @moduledoc """
  The conference has ended - all of its participants have left. Published when
  we are notified by the telephony provider that the conference has ended.
  """
  @derive [Poison.Encoder]
  @enforce_keys [:conference, :chair, :conference_sid]
  defstruct [
    conference: nil,
    chair: nil,
    conference_sid: nil
  ]

  @typedoc """
  Provides a reference to the conference.
  Fields:
    * `conference` - The conference identifier generated when a conference is requested
    * `chair` - The name of the conference chairperson
    * `conference_sid` - The sid of the conference provided by the telephony provider
  """
  @type t :: %__MODULE__{
    conference: String.t,
    chair: String.t,
    conference_sid: String.t
  }
end
