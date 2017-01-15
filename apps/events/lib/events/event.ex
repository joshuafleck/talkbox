defmodule Events.Event do
  @moduledoc """
  Documentation for Events.
  """
  @derive [Poison.Encoder]
  defstruct [
    created_at: nil,
    type: nil,
    payload: nil
  ]

  @type t :: %__MODULE__{
    created_at: String.t,
    type: String.t,
    payload: struct()
  }
end
