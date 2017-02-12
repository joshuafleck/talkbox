defmodule Router.Web do

  def broadcast(user, message, conference) do
    Ui.Endpoint.broadcast(channel(user), "conference_changed", %{message: message, conference: conference_message(conference)})
  end

  defp channel(user) do
    "twilio:" <> user
  end

  defp conference_message(conference) when is_nil(conference), do: nil
  defp conference_message(conference) do
    %{
      identifier: conference.identifier,
      chair: call_leg_message(conference.chair),
      pending_participant: call_leg_message(conference.pending_participant),
      participants: Enum.map(conference.participants, fn({call_sid, participant}) -> {call_sid, call_leg_message(participant)} end)
    }
  end

  defp call_leg_message(call_leg) when is_nil(call_leg), do: nil
  defp call_leg_message(call_leg) do
    %{
      identifier: call_leg.identifier,
      call_status: elem(call_leg.call_status, 0),
      call_sid: call_leg.call_sid
    }
  end
end
