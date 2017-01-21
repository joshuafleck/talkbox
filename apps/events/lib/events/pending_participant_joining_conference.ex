defmodule Events.PendingParticipantJoiningConference do
  @moduledoc """
  Documentation for Events.
  """
  @derive [Poison.Encoder]
  @enforce_keys [:conference, :chair, :pending_participant]
  defstruct [
    conference: nil,
    chair: nil,
    pending_participant: nil
  ]

  @type t :: %__MODULE__{
    conference: String.t,
    chair: String.t,
    pending_participant: String.t
  }
end
