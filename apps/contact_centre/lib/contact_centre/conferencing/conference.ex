defmodule ContactCentre.Conferencing.Conference do
  @moduledoc """
  This module is responsible for representing the
  conference and associated call legs, allowing the application to make
  decisions without needing to query the telephony provider for the state
  of the conference or any of its call legs.
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
    identifier: ContactCentre.Conferencing.Identifier.t,
    chairpersons_call_identifier: ContactCentre.Conferencing.Identifier.t,
    providers_identifier: String.t | nil,
    calls: %{required(ContactCentre.Conferencing.Identifier.t) => ContactCentre.Conferencing.Call.t}
  }

  @type success :: {:ok, t}
  @type success_with_call :: {:ok, t, ContactCentre.Conferencing.Call.t}
  @type fail :: {:error, String.t}
  @type response :: success | fail
  @type response_with_call :: success_with_call | fail

  @doc """
  Returns the call leg of the chairperson
  """
  @spec chairpersons_call(t) :: ContactCentre.Conferencing.Call.t | nil
  def chairpersons_call(conference) do
    Map.get(conference.calls, conference.chairpersons_call_identifier)
  end

  @doc """
  True, if the provided call identifier matches that of the chairperson
  """
  @spec chairpersons_call?(t, ContactCentre.Conferencing.Identifier.t) :: boolean
  def chairpersons_call?(conference, call_identifier) do
    conference.chairpersons_call_identifier == call_identifier
  end

  @doc """
  Returns true if the chairperson is alone in the conference
  """
  @spec chairperson_is_alone?(t) :: boolean
  def chairperson_is_alone?(conference) do
    [conference.chairpersons_call_identifier] == Map.keys(conference.calls)
  end

  @doc """
  Searches for a call that has a matching call identifier
  or provider's call identifier
  """
  @spec search_for_call(t, ContactCentre.Conferencing.Identifier.t | String.t) :: ContactCentre.Conferencing.Call.t | nil
  def search_for_call(conference, call_identifier) do
    case Map.get(conference.calls, call_identifier) do
      nil ->
        Enum.find(Map.values(conference.calls), fn call -> call.providers_identifier == call_identifier end)
      call ->
        call
    end
  end

  @doc """
  Returns a list of calls that have been requested
  from the telephony provider.
  """
  @spec requested_calls(t) :: [ContactCentre.Conferencing.Call]
  def requested_calls(conference) do
    Enum.filter(Map.values(conference.calls), &ContactCentre.Conferencing.Call.requested?(&1))
  end

  @doc """
  Returns a list of calls that have yet to be requested
  to the telephony provider.
  """
  @spec pending_calls(t) :: [ContactCentre.Conferencing.Call]
  def pending_calls(conference) do
    Enum.reject(Map.values(conference.calls), &ContactCentre.Conferencing.Call.requested?(&1))
  end

  @doc """
  Returns true if the conference has no calls
  """
  @spec empty?(t) :: boolean
  def empty?(conference) do
    Enum.empty?(conference.calls)
  end

  @doc """
  Creates a conference with the provided chairperson and destination.
  """
  @spec new(String.t, String.t) :: t
  def new(chairperson, destination) do
    chairpersons_call = ContactCentre.Conferencing.Call.new(chairperson)
    destination_call = ContactCentre.Conferencing.Call.new(destination)
    calls = [chairpersons_call, destination_call]
    |> Enum.map(fn call -> {call.identifier, call} end)
    |> Map.new

    %__MODULE__{
      identifier: ContactCentre.Conferencing.Identifier.get_next(),
      chairpersons_call_identifier: chairpersons_call.identifier,
      calls: calls
    }
  end

  @doc """
  Sets the provider's identifier on the specified call leg.
  Returns an error if the provider's identifier is already set to something different.
  """
  @spec set_providers_identifier_on_call(t, ContactCentre.Conferencing.Call.t, String.t) :: response_with_call
  def set_providers_identifier_on_call(conference, call, providers_identifier) do
    case call.providers_identifier do
      nil ->
        call = %{call | providers_identifier: providers_identifier}
        calls = Map.put(conference.calls, call.identifier, call)
        conference = %{conference | calls: calls}
        {:ok, conference, call}
      ^providers_identifier ->
        {:ok, conference, call}
      _ ->
        {:error, "providers_identifier already set on call"}
    end
  end

  @doc """
  Sets the provider's identifier for the conference.
  Returns an error if the conference identifier is already set to something different.
  """
  @spec set_providers_identifier(t, String.t) :: response
  def set_providers_identifier(conference, providers_identifier) do
    case conference.providers_identifier do
      nil ->
        conference = %{conference | providers_identifier: providers_identifier}
        {:ok, conference}
      ^providers_identifier ->
        {:ok, conference}
      _ ->
        {:error, "providers_identifier already set"}
    end
  end

  @doc """
  Removes the call from the conference
  """
  @spec remove_call(t, ContactCentre.Conferencing.Call.t) :: t
  def remove_call(conference, call) do
    %{conference | calls: Map.delete(conference.calls, call.identifier)}
  end

  @doc """
  Adds a call to the conference
  """
  @spec add_call(t, String.t) :: t
  def add_call(conference, destination) do
    call = ContactCentre.Conferencing.Call.new(destination)
    calls = Map.put(conference.calls, call.identifier, call)
    %{conference | calls: calls}
  end

  @doc """
  Updates the status of the call leg to the provided call status.
  Returns an error if the provided sequence number is not greater than the
  sequence number associated with the current call status.
  """
  @spec update_status_of_call(t, ContactCentre.Conferencing.Call.t, String.t, non_neg_integer) :: response_with_call
  def update_status_of_call(conference, call, status, sequence_number) do
    if ContactCentre.Conferencing.Call.newer_status?(call, sequence_number) do
      call = %{call | status: %ContactCentre.Conferencing.CallStatus{name: status, sequence: sequence_number}}
      calls = Map.put(conference.calls, call.identifier, call)
      conference = %{conference | calls: calls}
      {:ok, conference, call}
    else
      {:error, "call status has been superseded"}
    end
  end
end
