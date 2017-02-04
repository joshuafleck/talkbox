defmodule Telephony.Conference do
  @moduledoc """
  This module is responsible for maintaining the local state of the
  conference and associated call legs, allowing the application to make
  decisions without needing to query the telephony provider for the state
  of the conference or any of its call legs. The module also serves to
  protect the state of the conference from concurrency issues, for example:
  requests coming out of order. The system is designed such that if the local
  copy of the conference state is lost, it can be retrieved from the telephony
  provider with minimal interruption to ongoing calls.

  Suggested enhancements:
    * Upon startup, query the telephony provider for a list of in-progress conferences with which to prepopulate the local conference store.
  """
  use GenServer

  @enforce_keys [:identifier, :chair, :pending_participant, :created_at]
  defstruct [
    identifier: nil,
    chair: nil,
    sid: nil,
    pending_participant: nil,
    participants: %{},
    created_at: nil
  ]

  @typedoc """
  Internal representation of a conference.
  Fields:
    * `identifier` - The conference identifier we generate when a conference is requested
    * `chair` - The name of the conference chairperson
    * `sid` - The conference sid provided by the telephony provider, which we use when manipulating the conference state
    * `pending_participant` - Information about the call leg of the pending participant (i.e. the participant we wish to join to the conference)
    * `participants` - A map of call sid to call leg information about the conference participants
    * `created_at` - The time at which the conference was created
  """
  @type t :: %__MODULE__{
    identifier: String.t,
    chair: Telephony.Conference.Leg.t,
    sid: String.t,
    pending_participant: Telephony.Conference.Leg.t,
    participants: %{required(String.t) => Telephony.Conference.Leg.t},
    created_at: non_neg_integer
  }

  @type success :: {:ok, t}
  @type fail :: {:error, String.t}
  @type response :: success | fail
  @type conference_reference :: Telephony.Conference.Reference.t | Telephony.Conference.ParticipantReference.t | Telephony.Conference.PendingParticipantReference.t

  @doc """
  Determines if a conference has any participation (ongoing or pending)
  """
  @spec any_participants?(t) :: boolean
  def any_participants?(conference) do
    Enum.any?(conference.participants) || pending_participant?(conference)
  end

  @doc """
  Determines if a conference has a pending participant
  """
  @spec pending_participant?(t) :: boolean
  def pending_participant?(conference) do
    conference.pending_participant != nil
  end

  @doc """
  Determines if the chair has joined the conference
  """
  @spec chair_in_conference?(t) :: boolean
  def chair_in_conference?(conference) do
    conference.chair.call_sid != nil && conference.sid != nil
  end

  @doc """
  Determines if the provided call sid belongs to the chair
  """
  @spec chairs_call_sid?(t, String.t) :: boolean
  def chairs_call_sid?(conference, call_sid) do
    conference.chair.call_sid == call_sid
  end

  # Client

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Creates a conference with the provided chairperson and pending participant.
  Note that a chairperson may only have one conference at a time, so this
  overwrites any existing conference for the provided chairperson.
  """
  @spec create(String.t, String.t) :: response
  def create(chair, participant) do
    GenServer.call(__MODULE__, {:create, chair, participant})
  end

  @doc """
  Sets the provided call_sid on the chairperson's call leg.
  Returns an error if the call_sid is already set to something different.
  """
  @spec set_call_sid_on_chair(t, String.t) :: response
  def set_call_sid_on_chair(conference, call_sid) do
    GenServer.call(__MODULE__, {:set_call_sid_on_chair, conference, call_sid})
  end

  @doc """
  Removes the call_sid from the chairperson's call leg.
  Returns an error if the call_sid is set to something other than the
  provided call_sid.
  """
  @spec remove_call_sid_on_chair(t, String.t) :: response
  def remove_call_sid_on_chair(conference, call_sid) do
    GenServer.call(__MODULE__, {:remove_call_sid_on_chair, conference, call_sid})
  end

  @doc """
  Sets the sid for the conference.
  Returns an error if the conference sid is already set to something different.
  """
  @spec set_conference_sid(t, String.t) :: response
  def set_conference_sid(conference, conference_sid) do
    GenServer.call(__MODULE__, {:set_conference_sid, conference, conference_sid})
  end

  @doc """
  Sets the provided call_sid on the pending participant's call leg.
  Returns an error if the call_sid is already set to something different.
  """
  @spec set_call_sid_on_pending_participant(t, String.t) :: response
  def set_call_sid_on_pending_participant(conference, call_sid) do
    GenServer.call(
      __MODULE__,
      {:set_call_sid_on_pending_participant, conference, call_sid})
  end

  @doc """
  Removes the pending participant from the conference
  """
  @spec remove_pending_participant(Telephony.Conference.PendingParticipantReference.t) :: response
  def remove_pending_participant(pending_participant_reference) do
    GenServer.call(__MODULE__, {:remove_pending_participant, pending_participant_reference})
  end

  @doc """
  Sets the pending participant on the conference to the provided reference.
  Returns an error if the pending participant is already set.
  """
  @spec add_pending_participant(Telephony.Conference.PendingParticipantReference.t) :: response
  def add_pending_participant(pending_participant_reference) do
    GenServer.call(__MODULE__, {:add_pending_participant, pending_participant_reference})
  end

  @doc """
  Moves the pending participant call leg data from pending into the list of current participants.
  """
  @spec promote_pending_participant(t) :: response
  def promote_pending_participant(conference) do
    GenServer.call(__MODULE__, {:promote_pending_participant, conference})
  end

  @doc """
  Updates the call status of the pending participant to the provided call status.
  Returns an error if the provided sequence number is not greater than the
  sequence number associated with the current call status.
  """
  @spec update_call_status_of_pending_participant(Telephony.Conference.PendingParticipantReference.t, String.t, non_neg_integer) :: response
  def update_call_status_of_pending_participant(pending_participant_reference, call_status, sequence_number) do
    GenServer.call(__MODULE__, {:update_call_status_of_pending_participant, pending_participant_reference, call_status, sequence_number})
  end

  @doc """
  Removes the participant with the provided call_sid
  """
  @spec remove_participant(t, String.t) :: response
  def remove_participant(conference, call_sid) do
    GenServer.call(__MODULE__, {:remove_participant, conference, call_sid})
  end

  @doc """
  Removes the provided conference from the local store
  """
  @spec remove(t) :: response
  def remove(conference) do
    GenServer.call(__MODULE__, {:remove, conference})
  end

  @doc """
  Fetches the conference corresponding to the provided reference
  """
  @spec fetch(conference_reference) :: response
  def fetch(reference) do
    GenServer.call(__MODULE__, {:fetch, reference})
  end

  @doc """
  Fetches the conference corresponding to the provided reference
  """
  @spec fetch_by_pending_participant(Telephony.Conference.PendingParticipantReference.t) :: response
  def fetch_by_pending_participant(pending_participant_reference) do
    GenServer.call(__MODULE__, {:fetch_by_pending_participant, pending_participant_reference})
  end

  # Server (callbacks)

  def handle_call({:create, chair, participant}, _from, conferences) do
    conference = new(chair, participant)
    {:reply, {:ok, conference}, Map.put(conferences, conference.chair.identifier, conference)}
  end

  def handle_call({:set_call_sid_on_chair, conference, call_sid}, _from, conferences) do
    with_conference(conferences, reference(conference), fn conference ->
      case conference.chair.call_sid do
        nil ->
          conference = %{conference | chair: %{conference.chair | call_sid: call_sid}}
          {:reply, {:ok, conference}, Map.put(conferences, conference.chair.identifier, conference)}
        ^call_sid ->
          {:reply, {:ok, conference}, conferences}
        _ ->
          {:reply, {:error, "call_sid already set"}, conferences}
      end
    end)
  end

  def handle_call({:remove_call_sid_on_chair, conference, call_sid}, _from, conferences) do
    with_conference(conferences, reference(conference), fn conference ->
      case conference.chair.call_sid do
        nil ->
          {:reply, {:ok, conference}, conferences}
        ^call_sid ->
          conference = %{conference | chair: %{conference.chair | call_sid: nil}}
          {:reply, {:ok, conference}, Map.put(conferences, conference.chair.identifier, conference)}
        _ ->
          {:reply, {:error, "call_sid does not match"}, conferences}
      end
    end)
  end

  def handle_call({:set_conference_sid, conference, conference_sid}, _from, conferences) do
    with_conference(conferences, reference(conference), fn conference ->
      case conference.sid do
        nil ->
          conference = %{conference | sid: conference_sid}
          {:reply, {:ok, conference}, Map.put(conferences, conference.chair.identifier, conference)}
        ^conference_sid ->
          {:reply, {:ok, conference}, conferences}
        _ ->
          {:reply, {:error, "conference_sid already set"}, conferences}
      end
    end)
  end

  def handle_call({:set_call_sid_on_pending_participant, conference, call_sid}, _from, conferences) do
    with_conference_by_pending_participant(conferences, pending_participant_reference(conference), fn conference ->
      chairs_call_sid = conference.chair.call_sid
      case conference.pending_participant.call_sid do
        nil ->
          conference = %{conference | pending_participant: %{conference.pending_participant | call_sid: call_sid}}
          {:reply, {:ok, conference}, Map.put(conferences, conference.chair.identifier, conference)}
        ^call_sid ->
          {:reply, {:ok, conference}, conferences}
        ^chairs_call_sid ->
          {:reply, {:error, "call_sid of conference chair"}, conferences}
        _ ->
          {:reply, {:error, "call_sid already set"}, conferences}
      end
    end)
  end

  def handle_call({:remove_pending_participant, pending_participant_reference}, _from, conferences) do
    with_conference_by_pending_participant(conferences, pending_participant_reference, fn conference ->
      conference = %{conference | pending_participant: nil}
      {:reply, {:ok, conference}, Map.put(conferences, conference.chair.identifier, conference)}
    end)
  end

  def handle_call({:add_pending_participant, pending_participant_reference}, _from, conferences) do
    with_conference(conferences, pending_participant_reference, fn conference ->
      case conference do
        %{pending_participant: nil} ->
          conference = %{conference | pending_participant: %Telephony.Conference.Leg{identifier: pending_participant_reference.pending_participant_identifier}}
          {:reply, {:ok, conference}, Map.put(conferences, conference.chair.identifier, conference)}
        _ ->
          {:reply, {:error, "pending participant already set"}, conferences}
      end
    end)
  end

  def handle_call({:promote_pending_participant, conference}, _from, conferences) do
    with_conference_by_pending_participant(conferences, pending_participant_reference(conference), fn conference ->
      conference = %{conference | pending_participant: nil, participants: Map.put(conference.participants, conference.pending_participant.call_sid, conference.pending_participant)}
      {:reply, {:ok, conference}, Map.put(conferences, conference.chair.identifier, conference)}
    end)
  end

  def handle_call({:update_call_status_of_pending_participant, pending_participant_reference, call_status, sequence_number}, _from, conferences) do
    with_conference_by_pending_participant(conferences, pending_participant_reference, fn conference ->
      if elem(conference.pending_participant.call_status, 1) < sequence_number do
        conference = %{conference | pending_participant: %{conference.pending_participant | call_status: {call_status, sequence_number}}}
        {:reply, {:ok, conference}, Map.put(conferences, conference.chair.identifier, conference)}
      else
        {:reply, {:error, "call status has been superceded"}, conferences}
      end
    end)
  end

  def handle_call({:remove_participant, conference, call_sid}, _from, conferences) do
    with_conference(conferences, reference(conference), fn conference ->
      conference = %{conference | participants: Map.delete(conference.participants, call_sid)}
      {:reply, {:ok, conference}, Map.put(conferences, conference.chair.identifier, conference)}
    end)
  end

  def handle_call({:remove, conference}, _from, conferences) do
    with_conference(conferences, reference(conference), fn _ ->
      case Map.pop(conferences, conference.chair.identifier) do
        {nil, conferences} ->
          {:reply, {:error, "conference was not removed"}, conferences}
        {conference, conferences} ->
          {:reply, {:ok, conference}, conferences}
      end
    end)
  end

  def handle_call({:fetch, reference}, _from, conferences) do
    with_conference(conferences, reference, fn conference ->
      {:reply, {:ok, conference}, conferences}
    end)
  end

  def handle_call({:fetch_by_pending_participant, pending_participant_reference}, _from, conferences) do
    with_conference(conferences, pending_participant_reference, fn conference ->
      {:reply, {:ok, conference}, conferences}
    end)
  end

  # Internals

  @spec generate_identifier(String.t, DateTime.t) :: String.t
  defp generate_identifier(chair, current_unix_time) do
    current_unix_time = current_unix_time |> DateTime.to_unix(:milliseconds) |> Integer.to_string
    chair <> "_" <> current_unix_time
  end

  @spec reference(t) :: Telephony.Conference.Reference.t
  defp reference(conference) do
    %Telephony.Conference.Reference{identifier: conference.identifier, chair: conference.chair.identifier}
  end

  @spec pending_participant_reference(t) :: Telephony.Conference.PendingParticipantReference.t
  defp pending_participant_reference(conference) do
    %Telephony.Conference.PendingParticipantReference{
      identifier: conference.identifier,
      chair: conference.chair.identifier,
      pending_participant_identifier: conference.pending_participant.identifier}
  end

  @spec new(String.t, String.t) :: t
  defp new(chair, participant) do
    current_unix_time = DateTime.utc_now

    %__MODULE__{
      identifier: generate_identifier(chair, current_unix_time),
      chair: %Telephony.Conference.Leg{identifier: chair},
      pending_participant: %Telephony.Conference.Leg{identifier: participant},
      created_at: current_unix_time
    }
  end

  @spec with_conference(%{required(String.t) => t}, conference_reference, (t -> response)) :: {:reply, response, %{required(String.t) => t}}
  defp with_conference(conferences, reference, block) do
    conference = Map.get(conferences, reference.chair)
    identifier = reference.identifier
    case conference do
      %{identifier: ^identifier} ->
        block.(conference)
      _ ->
        {:reply, {:error, "matching conference not found"}, conferences}
    end
  end

  @spec with_conference_by_pending_participant(%{required(String.t) => t}, Telephony.Conference.PendingParticipantReference.t, (t -> response)) :: {:reply, response, %{required(String.t) => t}}
  defp with_conference_by_pending_participant(conferences, pending_participant_reference, block) do
    with_conference(conferences, pending_participant_reference, fn conference ->
      pending_participant_identifier = pending_participant_reference.pending_participant_identifier
      case conference do
        %{
          pending_participant: %{
            identifier: ^pending_participant_identifier
          }
        } ->
          block.(conference)
        _ ->
          {:reply, {:error, "matching conference not found"}, conferences}
      end
    end)
  end
end
