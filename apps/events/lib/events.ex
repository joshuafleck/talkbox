defmodule Events do
  @moduledoc """
  This module provides the ability for applications to publish events
  that can then be consumed and acted upon asyncronously. Each type of
  event will have its structure defined in a module within this app
  such that the producers and consumers of these events can include
  this application to ensure event definitions are the same for both
  the producers and consumers.
  """

  @typedoc """
  All of the possible events
  """
  @type t :: CallFailedToJoinConference.t
  | CallJoinedConference.t
  | CallLeftConference.t
  | CallRequested.t
  | CallRequestedFailed.t
  | CallStatusChanged.t
  | ChairpersonRequestsToRemoveCall.t
  | ConferenceEnded.t
  | HangupRequested.t
  | RemoveRequested.t
  | UserRequestsCall.t

  @doc """
  Subscribe to events of a given topic
  """
  @spec subscribe(atom) :: :ok
  def subscribe(topic) do
    Events.Registry.subscribe(topic)
  end

  @doc """
  Publish an event on a given topic
  """
  @spec publish(Events.t) :: :ok
  def publish(event) do
    Events.Registry.publish(event)
  end
end
