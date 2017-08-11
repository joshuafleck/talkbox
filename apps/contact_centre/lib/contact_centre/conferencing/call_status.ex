defmodule ContactCentre.Conferencing.CallStatus do
  @moduledoc """
  Represents a call status and the sequence in
  which the call status arrived (allowing us
  to identify call statuses that arrive out of order).
  """
  @enforce_keys [:name, :sequence]
  defstruct [
    name: nil,
    sequence: -1
  ]

  @type t :: %__MODULE__{
    name: String.t | nil,
    sequence: integer
  }
end
