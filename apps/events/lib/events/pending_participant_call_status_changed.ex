defmodule Events.PendingParticipantCallStatusChanged do
  @moduledoc """
  Documentation for Events.
  """
  @derive [Poison.Encoder]
  @enforce_keys [:conference, :chair, :pending_participant, :call_status]
  defstruct [
    conference: nil,
    chair: nil,
    pending_participant: nil,
    call_status: nil
  ]

  @type t :: %__MODULE__{
    conference: String.t,
    chair: String.t,
    pending_participant: String.t,
    call_status: String.t
  }
end
