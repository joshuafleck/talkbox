defmodule ContactCentre.Consumer do
  use GenServer
  @moduledoc """
  Responsible for consuming and actioning events pertaining to conferencing.
  """
  @subscriptions [Events.CallFailedToJoinConference,
                  Events.CallJoinedConference,
                  Events.CallLeftConference,
                  Events.CallStatusChanged,
                  Events.ChairpersonRequestsToRemoveCall,
                  Events.ConferenceEnded,
                  Events.UserRequestsCall,
                  Events.CallRequestFailed]
  use Events.Handler

  @spec handle(Events.UserRequestsCall.t) :: any
  def handle(event = %Events.UserRequestsCall{}) do
    case ContactCentre.Conferencing.add_participant_or_initiate_conference(event.user, event.callee, event.conference) do
      {:ok, conference} ->
        ContactCentre.Conferencing.Web.broadcast_conference_start(event.user, "Starting call", conference)
      {:error, message, conference} ->
        ContactCentre.Conferencing.Web.broadcast_conference_start(event.user, "Error starting call: #{message}", conference)
    end
  end

  @spec handle(Events.CallFailedToJoinConference.t) :: any
  def handle(event = %Events.CallFailedToJoinConference{}) do
    with {:ok, conference} <- ContactCentre.Conferencing.remove_call(event.conference, event.call) do
      ContactCentre.Conferencing.Web.broadcast_conference_changed("Failed to reach #{event.call}", conference)
    end
  end

  @spec handle(Events.CallRequestFailed.t) :: any
  def handle(event = %Events.CallRequestFailed{}) do
    with {:ok, conference} <- ContactCentre.Conferencing.remove_call(event.conference, event.call) do
      ContactCentre.Conferencing.Web.broadcast_conference_changed("Request for call #{event.call} failed", conference)
    end
  end

  @spec handle(Events.CallStatusChanged.t) :: any
  def handle(event = %Events.CallStatusChanged{}) do
    with {:ok, conference} <- ContactCentre.Conferencing.update_status_of_call(
           event.conference,
           event.call,
           event.providers_call_identifier,
           event.status,
           event.sequence_number) do
      ContactCentre.Conferencing.Web.broadcast_conference_changed("Call status changed for #{event.call}", conference)
    end
  end

  @spec handle(Events.CallJoinedConference.t) :: any
  def handle(event = %Events.CallJoinedConference{}) do
    result = ContactCentre.Conferencing.acknowledge_call_joined(
      event.conference,
      event.providers_identifier,
      event.providers_call_identifier)
    case result do
      {:ok, conference} ->
        ContactCentre.Conferencing.Web.broadcast_conference_changed("Someone joined", conference)
      {:error, message, conference} ->
        ContactCentre.Conferencing.Web.broadcast_conference_changed("Failed to join participant to conference due to: #{message}", conference)
    end
  end

  @spec handle(Events.CallLeftConference.t) :: any
  def handle(event = %Events.CallLeftConference{}) do
    with {:ok, conference} <- ContactCentre.Conferencing.acknowledge_call_left(event.conference, event.providers_call_identifier) do
      ContactCentre.Conferencing.Web.broadcast_conference_changed("Someone left", conference)
    end
  end

  @spec handle(Events.ConferenceEnded.t) :: any
  def handle(event = %Events.ConferenceEnded{}) do
    with {:ok, conference} <- ContactCentre.Conferencing.remove_conference(event.conference) do
      ContactCentre.Conferencing.Web.broadcast_conference_end("Call ended", conference)
    end
  end

  @spec handle(Events.ChairpersonRequestsToRemoveCall.t) :: any
  def handle(event = %Events.ChairpersonRequestsToRemoveCall{}) do
    ContactCentre.Conferencing.hangup_call(
      event.conference,
      event.call)
  end
end
