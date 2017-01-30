defmodule Telephony.Conference do
  @moduledoc """
  Conference storage: chair -> conference
  """

  @enforce_keys [:identifier, :chair, :pending_participant, :created_at]
  defstruct [
    identifier: nil,
    chair: nil,
    sid: nil,
    pending_participant: nil,
    participants: %{},
    created_at: nil
  ]

  @type t :: %__MODULE__{
    identifier: String.t,
    chair: Telephony.Participant.t,
    sid: String.t,
    pending_participant: Telephony.Participant.t,
    participants: map,
    created_at: non_neg_integer
  }

  # TODO: should this be a plain old gen server?
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

  def chair_joined_conference?(conference) do
    conference.sid != nil
  end

  def any_participants?(conference) do
    Enum.any?(conference.participants)
  end

  def chair_in_conference?(conference) do
    conference.chair.call_sid != nil
  end

  def chairs_call_sid?(conference, call_sid) do
    conference.chair.call_sid == call_sid
  end

  def set_call_sid_on_chair(chair, identifier, call_sid) do
    Agent.get_and_update(__MODULE__, &set_call_sid_on_chair(&1, chair, identifier, call_sid))
  end

  defp set_call_sid_on_chair(conferences, chair, identifier, call_sid) do
    with_conference(conferences, chair, identifier, fn conference ->
      case conference.chair.call_sid do
        nil ->
          conference = %{conference | chair: %{conference.chair | call_sid: call_sid}}
          {{:ok, conference}, Map.put(conferences, chair, conference)}
        ^call_sid ->
          {{:ok, conference}, conferences}
        _ ->
          {{:error, "call_sid already set"}, conferences}
      end
    end)
  end

  def remove_call_sid_on_chair(chair, identifier, call_sid) do
    Agent.get_and_update(__MODULE__, &remove_call_sid_on_chair(&1, chair, identifier, call_sid))
  end

  defp remove_call_sid_on_chair(conferences, chair, identifier, call_sid) do
    with_conference(conferences, chair, identifier, fn conference ->
      case conference.chair.call_sid do
        nil ->
          {{:ok, conference}, conferences}
        ^call_sid ->
          conference = %{conference | chair: %{conference.chair | call_sid: nil}}
          {{:ok, conference}, Map.put(conferences, chair, conference)}
        _ ->
          {{:error, "call_sid does not match"}, conferences}
      end
    end)
  end

  def set_conference_sid(chair, identifier, conference_sid) do
    Agent.get_and_update(__MODULE__, &set_conference_sid(&1, chair, identifier, conference_sid))
  end

  defp set_conference_sid(conferences, chair, identifier, conference_sid) do
    with_conference(conferences, chair, identifier, fn conference ->
      case conference.sid do
        nil ->
          conference = %{conference | sid: conference_sid}
          {{:ok, conference}, Map.put(conferences, chair, conference)}
        ^conference_sid ->
          {{:ok, conference}, conferences}
        _ ->
          {{:error, "conference_sid already set"}, conferences}
      end
    end)
  end

  def set_call_sid_on_pending_participant(chair, identifier, pending_participant_identifier, call_sid) do
    Agent.get_and_update(__MODULE__, &set_call_sid_on_pending_participant(&1, chair, identifier, pending_participant_identifier, call_sid))
  end

  defp set_call_sid_on_pending_participant(conferences, chair, identifier, pending_participant_identifier, call_sid) do
    with_conference_by_pending_participant(conferences, chair, identifier, pending_participant_identifier, fn conference ->
      case conference.pending_participant.call_sid do
        nil ->
          conference = %{conference | pending_participant: %{conference.pending_participant | call_sid: call_sid}}
          {{:ok, conference}, Map.put(conferences, chair, conference)}
        ^call_sid ->
          {{:ok, conference}, conferences}
        _ ->
          {{:error, "call_sid already set"}, conferences}
      end
    end)
  end

  def remove_pending_participant(chair, identifier, pending_participant_identifier) do
    Agent.get_and_update(__MODULE__, &remove_pending_participant(&1, chair, identifier, pending_participant_identifier))
  end

  defp remove_pending_participant(conferences, chair, identifier, pending_participant_identifier) do
    with_conference_by_pending_participant(conferences, chair, identifier, pending_participant_identifier, fn conference ->
      conference = %{conference | pending_participant: nil}
      {{:ok, conference}, Map.put(conferences, chair, conference)}
    end)
  end

  def add_pending_participant(chair, identifier, participant) do
    Agent.get_and_update(__MODULE__, &add_pending_participant(&1, chair, identifier, participant))
  end

  defp add_pending_participant(conferences, chair, identifier, participant) do
    with_conference(conferences, chair, identifier, fn conference ->
      case conference do
        %{pending_participant: nil} ->
          conference = %{conference | pending_participant: %Telephony.Participant{identifier: participant}}
          {{:ok, conference}, Map.put(conferences, chair, conference)}
        _ ->
          {{:error, "pending participant already set"}, conferences}
      end
    end)
  end

  def promote_pending_participant(chair, identifier, pending_participant_identifier) do
    Agent.get_and_update(__MODULE__, &promote_pending_participant(&1, chair, identifier, pending_participant_identifier))
  end

  defp promote_pending_participant(conferences, chair, identifier, pending_participant_identifier) do
    with_conference_by_pending_participant(conferences, chair, identifier, pending_participant_identifier, fn conference ->
      conference = %{conference | pending_participant: nil, participants: Map.put(conference.participants, conference.pending_participant.call_sid, conference.pending_participant)}
      {{:ok, conference}, Map.put(conferences, chair, conference)}
    end)
  end

  def update_call_status_of_pending_participant(chair, identifier, pending_participant_identifier, call_status, sequence_number) do
    Agent.get_and_update(__MODULE__, &update_call_status_of_pending_participant(&1, chair, identifier, pending_participant_identifier, call_status, sequence_number))
  end

  defp update_call_status_of_pending_participant(conferences, chair, identifier, pending_participant_identifier, call_status, sequence_number) do
    with_conference_by_pending_participant(conferences, chair, identifier, pending_participant_identifier, fn conference ->
      if elem(conference.pending_participant.call_status, 1) < sequence_number do
        conference = %{conference | pending_participant: %{conference.pending_participant | call_status: {call_status, sequence_number}}}
        {{:ok, conference}, Map.put(conferences, chair, conference)}
      else
        {{:error, "call status has been superceded"}, conferences}
      end
    end)
  end

  def remove_participant(chair, identifier, call_sid) do
    Agent.get_and_update(__MODULE__, &remove_participant(&1, chair, identifier, call_sid))
  end

  defp remove_participant(conferences, chair, identifier, call_sid) do
    with_conference(conferences, chair, identifier, fn conference ->
      conference = %{conference | participants: Map.delete(conference.participants, call_sid)}
      {{:ok, conference}, Map.put(conferences, chair, conference)}
    end)
  end

  def remove(chair, identifier) do
    Agent.get_and_update(__MODULE__, &remove(&1, chair, identifier))
  end

  defp remove(conferences, chair, identifier) do
    with_conference(conferences, chair, identifier, fn _ ->
      Map.pop(conferences, chair)
    end)
  end

  def fetch(chair, identifier) do
    with_conference(chair, identifier, fn conference -> {:ok, conference} end)
  end

  def fetch_by_pending_participant(chair, identifier, pending_participant_identifier) do
    with_conference_by_pending_participant(chair, identifier, pending_participant_identifier, fn conference -> {:ok, conference} end)
  end

  defp with_conference(chair, identifier, block) do
    Agent.get(__MODULE__, &with_conference(&1, chair, identifier, block))
  end

  # TODO: can this be turned into a method that yields to a block?
  # TODO: return an :error type rather than letting a no match exception bubble up
  defp with_conference(conferences, chair, identifier, block) do
    conference = Map.get(conferences, chair)
    case conference do
      %{identifier: ^identifier} ->
        block.(conference)
      _ ->
        {{:error, "matching conference not found"}, conferences}
    end
  end

  defp with_conference_by_pending_participant(chair, identifier, pending_participant_identifier, block) do
    Agent.get(__MODULE__, &with_conference_by_pending_participant(&1, chair, identifier, pending_participant_identifier, block))
  end

  defp with_conference_by_pending_participant(conferences, chair, identifier, pending_participant_identifier, block) do
    with_conference(conferences, chair, identifier, fn conference ->
      case conference do
        %{
          pending_participant: %{
            identifier: ^pending_participant_identifier
          }
        } ->
          block.(conference)
        _ ->
          {{:error, "matching conference not found"}, conferences}
      end
    end)
  end

  defp generate_identifier(chair, current_unix_time) do
    current_unix_time = current_unix_time |> DateTime.to_unix(:milliseconds) |> Integer.to_string
    chair <> "_" <> current_unix_time
  end

  defp create(conference) do
    Agent.update(__MODULE__, &Map.put(&1, conference.chair.identifier, conference))
  end
end
