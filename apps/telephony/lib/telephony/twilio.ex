defmodule Telephony.Twilio do
  @moduledoc """
  Twilio-specific telephony implementation
  """
  require Logger

  def call(
    to: to,
    from: from,
    url: url,
    status_callback: status_callback,
    status_callback_events: status_callback_events
  ) do # TODO: handle when the call is not successfully created
    Logger.debug "#{__MODULE__} calling #{to} from #{from} on #{url}"
    {:ok, call} = ExTwilio.Call.create([
      {:to, format_if_client(to)},
      {:from, from},
      {:url, url},
      {:status_callback, status_callback}
      ] ++ Enum.map(status_callback_events, &to_status_callback_event_tuple(&1)))
    call.sid
  end

  def hangup(call_sid) do # TODO: handle when the call is not successfully ended
    Logger.debug "#{__MODULE__} ending call with sid #{call_sid}"
    {:ok, call} = ExTwilio.Call.complete(%{sid: call_sid})
    call.sid
  end

  defp to_status_callback_event_tuple(status_callback_event) do
    {:status_callback_event, status_callback_event}
  end

  defp format_if_client(to) do
    if Regex.match?(~r/\+\d+/, to) do
      to
    else
      "client:" <> to
    end
  end
end
