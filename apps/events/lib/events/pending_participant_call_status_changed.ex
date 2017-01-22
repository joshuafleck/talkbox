defmodule Events.PendingParticipantCallStatusChanged do
  @moduledoc """
  Documentation for Events.
  """
  @derive [Poison.Encoder]
  @enforce_keys [:conference, :chair, :pending_participant, :call_status, :sequence_number]
  defstruct [
    conference: nil,
    chair: nil,
    pending_participant: nil,
    call_status: nil,
    sequence_number: nil
  ]

  @type t :: %__MODULE__{
    conference: String.t,
    chair: String.t,
    pending_participant: String.t,
    call_status: String.t,
    sequence_number: non_neg_integer
  }
end
