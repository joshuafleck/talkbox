defmodule Router.Web do
  @moduledoc """
  Responsible for encoding and sending messages in a format that can be handled by the
  client-side Javascript. This is where we trigger Websocket responses back to the clients.
  """

  @spec broadcast(String.t, String.t, Telephony.Conference.t | nil) :: any
  def broadcast(user, message, conference) do
    # TODO: log that we are broadcasing an event
    Ui.Endpoint.broadcast(channel(user), "conference_changed", %{message: message, conference: conference_message(conference)})
  end

  @spec channel(String.t) :: String.t
  defp channel(user) do
    "twilio:" <> user
  end

  @spec conference_message(Telephony.Conference.t) :: nil | map
  defp conference_message(conference) when is_nil(conference), do: nil
  defp conference_message(conference) do
    %{
      identifier: conference.identifier,
      chair: call_leg_message(conference.chair),
      pending_participant: call_leg_message(conference.pending_participant),
      participants: Enum.map(conference.participants, fn({_, participant}) -> call_leg_message(participant) end)
    }
  end

  @spec call_leg_message(Telephony.Conference.Leg.t) :: nil | map
  defp call_leg_message(call_leg) when is_nil(call_leg), do: nil
  defp call_leg_message(call_leg) do
    %{
      identifier: call_leg.identifier,
      call_status: elem(call_leg.call_status, 0),
      call_sid: call_leg.call_sid
    }
  end
end
