defmodule Events.UserRequestsCall do
  @moduledoc """
  Documentation for Events.
  """
  @derive [Poison.Encoder]
  @enforce_keys [:user, :callee]
  defstruct [
    user: nil,
    callee: nil
  ]

  @type t :: %__MODULE__{
    user: String.t,
    callee: String.t
  }
end
