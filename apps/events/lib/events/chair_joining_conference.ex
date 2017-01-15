defmodule Events.ChairJoiningConference do
  @moduledoc """
  Documentation for Events.
  """
  @derive [Poison.Encoder]
  defstruct [
    conference: nil,
    chair: nil
  ]

  @type t :: %__MODULE__{
    conference: String.t,
    chair: String.t
  }
end
