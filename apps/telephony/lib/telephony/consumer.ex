defmodule Telephony.Consumer do
  @moduledoc """
  Responsible for consuming and actioning events pertaining to call state changes.
  """
  @subscriptions [Events.CallRequested, Events.HangupRequested, Events.RemoveRequested]
  use Events.Handler
  alias TelephonyWeb.Router.Helpers
  alias TelephonyWeb.Endpoint

  require Logger

  @spec handle(Events.CallRequested.t) :: any
  def handle(event = %Events.CallRequested{}) do
    url_prefix = get_env(:webhook_url)
    from = get_env(:cli)
    conference_status_callback = url_prefix <> Helpers.conference_status_changed_path(Endpoint, :status_changed, event.conference)
    url = url_prefix <> Helpers.conference_call_answered_path(Endpoint, :answered, event.conference, event.call, conference_status_callback: conference_status_callback)
    status_callback = url_prefix <> Helpers.conference_call_status_changed_path(Endpoint, :status_changed, event.conference, event.call)
    result = log_api_call(:call, fn ->
      provider().call(
        to: event.destination,
        from: from,
        url: url,
        status_callback: status_callback,
        status_callback_events: ~w(initiated ringing answered completed))
    end)
    case result do
      {:error, _, _} ->
        Events.publish(%Events.CallRequestFailed{conference: event.conference, call: event.call})
        result
      _ ->
        result
    end
  end

  @spec handle(Events.HangupRequested.t) :: any
  def handle(event = %Events.HangupRequested{}) do
    log_api_call(:hangup, fn ->
      provider().hangup(event.providers_call_identifier)
    end)
  end

  @spec handle(Events.RemoveRequested.t) :: any
  def handle(event = %Events.RemoveRequested{}) do
    log_api_call(:kick_participant_from_conference, fn ->
      provider().kick_participant_from_conference(event.providers_identifier, event.providers_call_identifier)
    end)
  end

  @spec provider :: module
  defp provider do
    get_env(:provider)
  end

  @spec log_api_call(atom, (() -> Telephony.Provider.result)) :: Telephony.Provider.result
  defp log_api_call(description, api_call) do
    started_at = System.monotonic_time(:microseconds)
    result = api_call.()
    ended_at = System.monotonic_time(:microseconds)
    duration_in_ms = (ended_at - started_at) / 1000
    result_message = case result do
                       {:error, message, code} ->
                         "error (#{code}) #{message}"
                       _ ->
                         "success"
                     end
    Logger.info(fn ->
      "Telephony provider API call, description: #{description}, provider: #{provider()}, duration_in_ms: #{duration_in_ms}, result: #{result_message}"
    end)
    result
  end

  @spec get_env(atom) :: term
  defp get_env(key) do
    setting = Application.get_env(:telephony, key)
    if is_function(setting) do
      setting.()
    else
      setting
    end
  end
end
