defmodule ContactCentre.State.Web do
  @moduledoc """
  Responsible for encoding and sending messages in a format that can be handled by the
  client-side Javascript. This is where we trigger Websocket responses back to the clients.
  """
  @spec broadcast_conference_start(String.t, String.t, ContactCentre.State.Conference.t) :: any
  def broadcast_conference_start(user, message, conference) do
    ContactCentre.Web.Endpoint.broadcast("user:#{user}", "conference_started", %{message: message, conference: conference_message(conference)})
  end

  @spec broadcast_conference_end(String.t, ContactCentre.State.Conference.t) :: any
  def broadcast_conference_end(message, conference) do
    ContactCentre.Web.Endpoint.broadcast("conference:#{conference.identifier}", "conference_ended", %{message: message, conference: conference_message(conference)})
  end

  @spec broadcast_conference_changed(String.t, ContactCentre.State.Conference.t) :: any
  def broadcast_conference_changed(message, conference) do
    ContactCentre.Web.Endpoint.broadcast("conference:#{conference.identifier}", "conference_changed", %{message: message, conference: conference_message(conference)})
  end

  @spec conference_message(ContactCentre.State.Conference.t) :: nil | map
  defp conference_message(conference) when is_nil(conference), do: nil
  defp conference_message(conference) do
    participants = Map.values(conference.calls)
    %{
      identifier: conference.identifier,
      participants: Enum.map(participants, fn(participant) -> call_leg_message(participant) end)
    }
  end

  @spec call_leg_message(ContactCentre.State.Conference.Leg.t) :: nil | map
  defp call_leg_message(call_leg) when is_nil(call_leg), do: nil
  defp call_leg_message(call_leg) do
    %{
      identifier: call_leg.identifier,
      destination: call_leg.destination,
      call_status: elem(call_leg.status, 0),
      call_sid: call_leg.providers_identifier
    }
  end
end
