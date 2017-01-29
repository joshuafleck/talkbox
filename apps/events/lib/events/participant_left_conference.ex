defmodule Events.ParticipantLeftConference do
  @moduledoc """
  Documentation for Events.
  """
  @derive [Poison.Encoder]
  @enforce_keys [:conference, :chair, :call_sid, :conference_sid]
  defstruct [
    conference: nil,
    chair: nil,
    call_sid: nil,
    conference_sid: nil
  ]

  @type t :: %__MODULE__{
    conference: String.t,
    chair: String.t,
    call_sid: String.t,
    conference_sid: String.t
  }
end
