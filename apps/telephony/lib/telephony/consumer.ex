defmodule Telephony.Consumer do
  @moduledoc """
  Responsible for consuming and actioning events pertaining to call state changes.
  """
  @subscriptions [Events.CallRequested, Events.HangupRequested, Events.RemoveRequested]
  use Events.Handler

  require Logger

  @spec handle(Events.CallRequested.t) :: any
  def handle(event = %Events.CallRequested{}) do
    url_prefix = Application.get_env(:telephony, :webhook_url).()
    from = Application.get_env(:telephony, :cli).()
    conference_status_callback = url_prefix <> Telephony.Web.Router.Helpers.conference_status_changed_path(Telephony.Web.Endpoint, :status_changed, event.conference)
    url = url_prefix <> Telephony.Web.Router.Helpers.conference_call_answered_path(Telephony.Web.Endpoint, :answered, event.conference, event.call, conference_status_callback: conference_status_callback)
    status_callback = url_prefix <> Telephony.Web.Router.Helpers.conference_call_status_changed_path(Telephony.Web.Endpoint, :status_changed, event.conference, event.call)
    result = Telephony.Consumer.log_api_call(:call, fn ->
      Telephony.Consumer.provider.call(
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
    Telephony.Consumer.log_api_call(:hangup, fn ->
      Telephony.Consumer.provider.hangup(event.providers_call_identifier)
    end)
  end

  @spec handle(Events.RemoveRequested.t) :: any
  def handle(event = %Events.RemoveRequested{}) do
    Telephony.Consumer.log_api_call(:kick, fn ->
      Telephony.Consumer.provider.kick_participant_from_conference(event.providers_identifier, event.providers_call_identifier)
    end)
  end

  @spec provider :: module
  def provider do
    Application.get_env(:telephony, :provider)
  end

  @spec log_api_call(atom, (() -> Telephony.Provider.result)) :: Telephony.Provider.result
  def log_api_call(description, api_call) do
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
end
