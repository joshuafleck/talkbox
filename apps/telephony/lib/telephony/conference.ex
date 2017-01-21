defmodule Telephony.Conference do
  @moduledoc """
  Conference storage: chair -> conference
  """

  @enforce_keys [:identifier, :chair, :pending_participant, :created_at]
  defstruct [
    identifier: nil,
    chair: nil,
    pending_participant: nil,
    participants: [],
    created_at: nil
  ]

  @type t :: %__MODULE__{
    identifier: String.t,
    chair: Telephony.Participant.t,
    pending_participant: Telephony.Participant.t,
    participants: list,
    created_at: non_neg_integer
  }

  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def new(chair, participant) do
    current_unix_time = DateTime.utc_now

    %__MODULE__{
      identifier: generate_identifier(chair, current_unix_time),
      chair: %Telephony.Participant{identifier: chair},
      pending_participant: %Telephony.Participant{identifier: participant},
      created_at: current_unix_time
    }
  end

  def create(chair, participant) do
    conference = new(chair, participant)
    :ok = create(conference)
    conference
  end

  def get(chair) do
    Agent.get(__MODULE__, &Map.get(&1, chair))
  end

  def update(chair, function) do
    Agent.get_and_update(__MODULE__, &Map.get_and_update(&1, chair, function))
  end

  defp generate_identifier(chair, current_unix_time) do
    current_unix_time = current_unix_time |> DateTime.to_unix(:milliseconds) |> Integer.to_string
    chair <> "_" <> current_unix_time
  end

  defp create(conference) do
    Agent.update(__MODULE__, &Map.put(&1, conference.chair.identifier, conference))
  end
end
