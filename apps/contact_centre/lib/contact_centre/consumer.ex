defmodule ContactCentre.Consumer do
  use GenServer
  @moduledoc """
  Responsible for consuming and actioning events pertaining to conferencing.
  """
  @subscriptions [Events.CallFailedToJoinConference,
                  Events.CallJoinedConference,
                  Events.CallLeftConference,
                  Events.CallRequestFailed,
                  Events.CallStatusChanged,
                  Events.ChairpersonRequestsToRemoveCall,
                  Events.ConferenceCreated,
                  Events.ConferenceDeleted,
                  Events.ConferenceEnded,
                  Events.ConferenceUpdated,
                  Events.UserRequestsCall]
  use Events.Handler

  @spec handle(Events.ConferenceCreated.t) :: any
  def handle(event = %Events.ConferenceCreated{}) do
    ContactCentre.Conferencing.Web.broadcast_conference_created(event.user, event.conference)
  end

  @spec handle(Events.ConferenceUpdated.t) :: any
  def handle(event = %Events.ConferenceUpdated{}) do
    ContactCentre.Conferencing.Web.broadcast_conference_updated(event.reason, event.conference)
  end

  @spec handle(Events.ConferenceDeleted.t) :: any
  def handle(event = %Events.ConferenceDeleted{}) do
    ContactCentre.Conferencing.Web.broadcast_conference_deleted(event.conference)
  end

  @spec handle(Events.UserRequestsCall.t) :: any
  def handle(event = %Events.UserRequestsCall{}) do
    ContactCentre.Conferencing.add_participant_or_initiate_conference(event.user, event.callee, event.conference)
  end

  @spec handle(Events.CallFailedToJoinConference.t) :: any
  def handle(event = %Events.CallFailedToJoinConference{}) do
    ContactCentre.Conferencing.remove_call(event.conference, event.call)
  end

  @spec handle(Events.CallRequestFailed.t) :: any
  def handle(event = %Events.CallRequestFailed{}) do
    ContactCentre.Conferencing.remove_call(event.conference, event.call, event.reason)
  end

  @spec handle(Events.CallStatusChanged.t) :: any
  def handle(event = %Events.CallStatusChanged{}) do
    ContactCentre.Conferencing.update_status_of_call(
           event.conference,
           event.call,
           event.providers_call_identifier,
           event.status,
           event.sequence_number)
  end

  @spec handle(Events.CallJoinedConference.t) :: any
  def handle(event = %Events.CallJoinedConference{}) do
    ContactCentre.Conferencing.acknowledge_call_joined(
      event.conference,
      event.providers_identifier,
      event.providers_call_identifier)
  end

  @spec handle(Events.CallLeftConference.t) :: any
  def handle(event = %Events.CallLeftConference{}) do
    ContactCentre.Conferencing.acknowledge_call_left(event.conference, event.providers_call_identifier)
  end

  @spec handle(Events.ConferenceEnded.t) :: any
  def handle(event = %Events.ConferenceEnded{}) do
    ContactCentre.Conferencing.remove_conference(event.conference)
  end

  @spec handle(Events.ChairpersonRequestsToRemoveCall.t) :: any
  def handle(event = %Events.ChairpersonRequestsToRemoveCall{}) do
    ContactCentre.Conferencing.hangup_call(
      event.conference,
      event.call)
  end
end
