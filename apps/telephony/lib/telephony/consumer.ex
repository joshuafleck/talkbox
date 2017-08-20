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
    url_prefix = from_env(:telephony, :webhook_url)
    from = from_env(:telephony, :cli)
    conference_status_callback = url_prefix <> Helpers.conference_status_changed_path(Endpoint, :status_changed, event.conference)
    url = url_prefix <> Helpers.conference_call_answered_path(Endpoint, :answered, event.conference, event.call, conference_status_callback: conference_status_callback)
    status_callback = url_prefix <> Helpers.conference_call_status_changed_path(Endpoint, :status_changed, event.conference, event.call)
    result = make_api_call(:call, fn ->
      provider().call(
        to: event.destination,
        from: from,
        url: url,
        status_callback: status_callback,
        status_callback_events: ~w(initiated ringing answered completed))
    end)
    case result do
      {:error, reason, _} ->
        Events.publish(%Events.CallRequestFailed{conference: event.conference, call: event.call, reason: reason})
        result
      _ ->
        result
    end
  end

  @spec handle(Events.HangupRequested.t) :: any
  def handle(event = %Events.HangupRequested{}) do
    make_api_call(:hangup, fn ->
      provider().hangup(event.providers_call_identifier)
    end)
  end

  @spec handle(Events.RemoveRequested.t) :: any
  def handle(event = %Events.RemoveRequested{}) do
    make_api_call(:kick_participant_from_conference, fn ->
      provider().kick_participant_from_conference(event.providers_identifier, event.providers_call_identifier)
    end)
  end

  @spec provider :: module
  defp provider do
    from_env(:telephony, :provider)
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

  @spec from_env(atom, atom) :: term
  defp from_env(otp_app, key) do
    otp_app
    |> Application.get_env(key)
    |> read_from_system()
    |> raise_if_missing(otp_app, key)
  end

  defp read_from_system({:system, env}), do: System.get_env(env)
  defp read_from_system(value) when is_function(value), do: value.()
  defp read_from_system(value), do: value

  defp raise_if_missing(value, otp_app, key) when is_nil(value) or length(value) == 0 do
    raise "The configuration setting `#{key}` in the `#{otp_app}` application is not set, unable to proceed."
  end
  defp raise_if_missing(value, _otp_app, _key), do: value

  @spec timeout(non_neg_integer, (() -> Telephony.Provider.result)) :: Telephony.Provider.result
  defp timeout(seconds, function) do
    task = Task.async(function)
    timeout = seconds * 1000
    case Task.yield(task, timeout) || Task.shutdown(task) do
      {:ok, result} ->
        result
      nil ->
        {:error, "Failed to get a result in #{seconds} seconds", 0}
    end
  end

  @spec make_api_call(atom, (() -> Telephony.Provider.result), non_neg_integer) :: Telephony.Provider.result
  defp make_api_call(description, api_call, timeout_in_seconds \\ 2) do
    log_api_call(description, fn ->
      timeout(timeout_in_seconds, api_call)
    end)
  end
end
