defmodule Events.ChairJoiningConference do
  @moduledoc """
  Documentation for Events.
  """
  @derive [Poison.Encoder]
  @enforce_keys [:conference, :chair]
  defstruct [
    conference: nil,
    chair: nil
  ]

  @type t :: %__MODULE__{
    conference: String.t,
    chair: String.t
  }
end
