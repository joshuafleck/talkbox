defmodule Callbacks.Provider.Twilio do
  @moduledoc """
  This module encapsulates all calls to Twilio for managing call and conference state.
  The telephony-specific logic is encapsulated in one module to enable swapping out
  telephony logic with stubs in tests, but also in case we want to introduce support
  for additional telephony providers.
  """
  require Logger
  @behaviour Callbacks.Provider

  @doc """
  Initiates a telephone call.
  Args:
    * `to` - The telephone number or client name of the callee
    * `from` - The CLI of the caller
    * `url` - The callback URL on which Twilio will send a request for further instruction upon the callee answering the call
    * `status_callback` - The callback URL on which Twilio will send a request when the status of the call changes
    * `status_callback_events` - The events for which we will receive status callbacks
  This function returns `{:ok, call_sid}` if the request is successful, `{:error, message, code}` otherwise.
  ## Examples
      call(to: "+4412345678901", from: "+4412345678902", url: "http://test.com/call_answered", status_callback: "http://test.com/call_status_changed", status_callback_events: ["completed"])
  """
  def call(
    to: to,
    from: from,
    url: url,
    status_callback: status_callback,
    status_callback_events: status_callback_events
  ) do
    Logger.debug fn -> "#{__MODULE__} calling #{to} from #{from} on #{url}" end
    result = ExTwilio.Call.create([
      {:to, format_if_client(to)},
      {:from, from},
      {:url, url},
      {:status_callback, status_callback}
      ] ++ Enum.map(status_callback_events, &to_status_callback_event_tuple(&1)))
    case result do
      {:ok, call_data} ->
        {:ok, call_data.sid}
      error ->
        error
    end
  end

  @doc """
  Ends a telephone call.
  Args:
    * `call_sid` - The call sid of the call to hang up
  This function returns `{:ok, call_sid}` if the request is successful, `{:error, message, code}` otherwise.
  ## Examples
      hangup("call_sid1234")
  """
  def hangup(call_sid) do
    Logger.debug fn -> "#{__MODULE__} ending call with sid #{call_sid}" end
    result = ExTwilio.Call.complete(call_sid)
    case result do
      {:ok, call_data} ->
        {:ok, call_data.sid}
      error ->
        error
    end
  end

  @doc """
  Removes a participant from a conference.
  Args:
    * `conference_sid` - The sid of the conference containing the participant
    * `call_sid` - The call sid of the call
  This function returns `{:ok, call_sid}` if the request is successful, `{:error, message, code}` otherwise.
  ## Examples
      kick_participant_from_conference("conference_sid1234","call_sid1234")
  """
  def kick_participant_from_conference(conference_sid, call_sid) do
    Logger.debug fn -> "#{__MODULE__} kicking participant with sid #{call_sid} from conference #{conference_sid}" end
    result = ExTwilio.Participant.destroy(call_sid, [{:conference, conference_sid}])
    case result do
      :ok ->
        {:ok, call_sid}
      error ->
        error
    end
  end

  @spec to_status_callback_event_tuple(String.t) :: {:status_callback_event, String.t}
  defp to_status_callback_event_tuple(status_callback_event) do
    {:status_callback_event, status_callback_event}
  end

  @spec format_if_client(String.t) :: String.t
  defp format_if_client(to) do
    if Regex.match?(~r/\+\d+/, to) do
      to
    else
      "client:" <> to
    end
  end
end
