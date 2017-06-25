defmodule ContactCentre.State.Conference do
  @moduledoc """
  This module is responsible for maintaining the local state of the
  conference and associated call legs, allowing the application to make
  decisions without needing to query the telephony provider for the state
  of the conference or any of its call legs. The module also serves to
  protect the state of the conference from concurrency issues, for example:
  requests coming out of order. The system is designed such that if the local
  copy of the conference state is lost, it can be retrieved from the telephony
  provider with minimal interruption to ongoing calls.
  """
  use GenServer

  @enforce_keys [:identifier, :chairpersons_call_identifier, :calls]
  defstruct [
    identifier: nil,
    chairpersons_call_identifier: nil,
    providers_identifier: nil,
    calls: nil
  ]

  @typedoc """
  Internal representation of a conference.
  Fields:
    * `identifier` - The conference identifier we generate when a conference is requested
    * `chairpersons_call_identifier` - Denotes which call belongs to the chairperson of the conference
    * `providers_identifier` - The conference identifier provided by the telephony provider, which we use when manipulating the conference state
    * `calls` - A map of call identifier to call leg information about the conference participants
  """
  @type t :: %__MODULE__{
    identifier: ContactCentre.State.Indentifier.t,
    chairpersons_call_identifier: ContactCentre.State.Indentifier.t,
    providers_identifier: String.t | nil,
    calls: %{required(ContactCentre.State.Indentifier.t) => ContactCentre.State.Conference.Call.t}
  }

  @type success :: {:ok, t}
  @type fail :: {:error, String.t}
  @type response :: success | fail
  @type store :: %{required(ContactCentre.State.Indentifier.t) => t}

  # Client

  @doc """
  Starts a singleton GenServer
  """
  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Creates a conference with the provided chairperson and destination.
  """
  @spec create(String.t, String.t) :: response
  def create(chairperson, destination) do
    GenServer.call(__MODULE__, {:create, chairperson, destination})
  end

  @doc """
  Returns the call leg of the chairperson
  """
  @spec chairpersons_call(t) :: ContactCentre.State.Conference.Call.t | nil
  def chairpersons_call(conference) do
    Map.get(conference.calls, conference.chairpersons_call_identifier)
  end

  @doc """
  True, if the provided call identifier matches that of the chairperson
  """
  @spec chairpersons_call?(t, ContactCentre.State.Indentifier.t) :: boolean
  def chairpersons_call?(conference, call_identifier) do
    conference.chairpersons_call_identifier == call_identifier
  end

  @doc """
  Sets the provider's identifier on the specified call leg.
  Returns an error if the provider's identifier is already set to something different.
  """
  @spec set_providers_identifier_on_call(t, ContactCentre.State.Indentifier.t, String.t) :: response
  def set_providers_identifier_on_call(conference, call_identifier, providers_identifier) do
    GenServer.call(__MODULE__, {:set_providers_identifier_on_call, conference, call_identifier, providers_identifier})
  end

  @doc """
  Sets the provider's identifier for the conference.
  Returns an error if the conference identifier is already set to something different.
  """
  @spec set_providers_identifier(t, String.t) :: response
  def set_providers_identifier(conference, providers_identifier) do
    GenServer.call(__MODULE__, {:set_providers_identifier, conference, providers_identifier})
  end

  @doc """
  Removes the call from the conference
  """
  @spec remove_call(t, ContactCentre.State.Indentifier.t) :: response
  def remove_call(conference, call_identifier) do
    GenServer.call(__MODULE__, {:remove_call, conference, call_identifier})
  end

  @doc """
  Adds a call to the conference
  """
  @spec add_call(t, String.t) :: response
  def add_call(conference, destination) do
    GenServer.call(__MODULE__, {:add_call, conference, destination})
  end

  @doc """
  Updates the status of the call leg to the provided call status.
  Returns an error if the provided sequence number is not greater than the
  sequence number associated with the current call status.
  """
  @spec update_status_of_call(t, ContactCentre.State.Indentifier.t, String.t, non_neg_integer) :: response
  def update_status_of_call(conference, call_identifier, status, sequence_number) do
    GenServer.call(__MODULE__, {:update_status_of_call, conference, call_identifier, status, sequence_number})
  end

  @doc """
  Removes the provided conference from the local store
  """
  @spec remove(t) :: response
  def remove(conference) do
    GenServer.call(__MODULE__, {:remove, conference})
  end

  @doc """
  Fetches the conference corresponding to the provided identifier
  """
  @spec fetch(ContactCentre.State.Indentifier.t) :: response
  def fetch(identifier) do
    GenServer.call(__MODULE__, {:fetch, identifier})
  end

  # Server (callbacks)

  def handle_call({:create, chairperson, destination}, _from, conferences) do
    conference = new(chairperson, destination)
    {:reply, {:ok, conference}, Map.put(conferences, conference.identifier, conference)}
  end

  def handle_call({:set_providers_identifier_on_call, conference, call_identifier, providers_identifier}, _from, conferences) do
    with_conference_and_call(conferences, conference.identifier, call_identifier, fn conference, call ->
      case call.providers_identifier do
        nil ->
          call = %{call | providers_identifier: providers_identifier}
          calls = Map.put(conference.calls, call.identifier, call)
          conference = %{conference | calls: calls}
          {:reply, {:ok, conference}, Map.put(conferences, conference.identifier, conference)}
        ^providers_identifier ->
          {:reply, {:ok, conference}, conferences}
        _ ->
          {:reply, {:error, "providers_identifier already set on call"}, conferences}
      end
    end)
  end

  def handle_call({:set_providers_identifier, conference, providers_identifier}, _from, conferences) do
    with_conference(conferences, conference.identifier, fn conference ->
      case conference.providers_identifier do
        nil ->
          conference = %{conference | providers_identifier: providers_identifier}
          {:reply, {:ok, conference}, Map.put(conferences, conference.identifier, conference)}
        ^providers_identifier ->
          {:reply, {:ok, conference}, conferences}
        _ ->
          {:reply, {:error, "providers_identifier already set"}, conferences}
      end
    end)
  end

  def handle_call({:remove_call, conference, call_identifier}, _from, conferences) do
    with_conference_and_call(conferences, conference.identifier, call_identifier, fn conference, call ->
      conference = %{conference | calls: Map.delete(conference.calls, call.identifier)}
      {:reply, {:ok, conference}, Map.put(conferences, conference.identifier, conference)}
    end)
  end

  def handle_call({:add_call, conference, destination}, _from, conferences) do
    with_conference(conferences, conference.identifier, fn conference ->
      call = %ContactCentre.State.Conference.Call{identifier: ContactCentre.State.Identifier.get_next(), destination: destination}
      calls = Map.put(conference.calls, call.identifier, call)
      conference = %{conference | calls: calls}
      {:reply, {:ok, conference}, Map.put(conferences, conference.identifier, conference)}
    end)
  end

  def handle_call({:update_status_of_call, conference, call_identifier, status, sequence_number}, _from, conferences) do
    with_conference_and_call(conferences, conference.identifier, call_identifier, fn conference, call ->
      if elem(call.status, 1) < sequence_number do
        call = %{call | status: {status, sequence_number}}
        calls = Map.put(conference.calls, call.identifier, call)
        conference = %{conference | calls: calls}
        {:reply, {:ok, conference}, Map.put(conferences, conference.identifier, conference)}
      else
        {:reply, {:error, "call status has been superceded"}, conferences}
      end
    end)
  end

  def handle_call({:remove, conference}, _from, conferences) do
    case Map.pop(conferences, conference.identifier) do
      {nil, conferences} ->
        {:reply, {:error, "conference was not removed"}, conferences}
      {conference, conferences} ->
        {:reply, {:ok, conference}, conferences}
    end
  end

  def handle_call({:fetch, identifier}, _from, conferences) do
    case with_conference(conferences, identifier,
          fn conference ->
            {:reply, {:ok, conference}, conferences}
          end) do
      {:reply, {:error, _}, _} ->
        {:reply, nil, conferences}
      result ->
        result
    end
  end

  # Internals

  @spec new(String.t, String.t) :: t
  defp new(chairperson, destination) do
    calls = Enum.map([chairperson, destination], fn destination ->
      %ContactCentre.State.Conference.Call{identifier: ContactCentre.State.Identifier.get_next(), destination: destination}
    end)
    %__MODULE__{
      identifier: ContactCentre.State.Identifier.get_next(),
      chairpersons_call_identifier: Enum.at(calls, 0).identifier,
      calls: Enum.map(calls, fn call -> {call.identifier, call} end) |> Map.new
    }
  end

  @spec with_conference(store, ContactCentre.State.Indentifier.t, (t -> response)) :: {:reply, response, store}
  defp with_conference(conferences, identifier, block) do
    case Map.get(conferences, identifier) do
      nil ->
        {:reply, {:error, "matching conference not found"}, conferences}
      conference ->
        block.(conference)
    end
  end

  @spec with_conference_and_call(store, ContactCentre.State.Indentifier.t, ContactCentre.State.Indentifier.t | String.t, ((t, ContactCentre.State.Conference.Call.t) -> response)) :: {:reply, response, store}
  defp with_conference_and_call(conferences, identifier, call_identifier, block) do
    with_conference(conferences, identifier, fn conference ->
      case Map.get(conference.calls, call_identifier) do
        nil ->
          case Enum.find(Map.values(conference.calls), fn call -> call.providers_identifier == call_identifier end) do
            nil ->
              {:reply, {:error, "matching call not found"}, conferences}
            call ->
              block.(conference, call)
          end
        call ->
          block.(conference, call)
      end
    end)
  end
end
