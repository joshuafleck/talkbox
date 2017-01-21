defmodule Events.ChairFailedToJoinConference do
  @moduledoc """
  Documentation for Events.
  """
  @derive [Poison.Encoder]
  @enforce_keys [:conference, :chair, :reason]
  defstruct [
    conference: nil,
    chair: nil,
    reason: nil
  ]

  @type t :: %__MODULE__{
    conference: String.t,
    chair: String.t,
    reason: String.t
  }
end
