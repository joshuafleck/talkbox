defmodule Events.ConferenceEnded do
  @moduledoc """
  Documentation for Events.
  """
  @derive [Poison.Encoder]
  @enforce_keys [:conference, :chair, :conference_sid]
  defstruct [
    conference: nil,
    chair: nil,
    conference_sid: nil
  ]

  @type t :: %__MODULE__{
    conference: String.t,
    chair: String.t,
    conference_sid: String.t
  }
end
