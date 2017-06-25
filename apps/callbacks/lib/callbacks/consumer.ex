defmodule Callbacks.Consumer do
  use GenServer
  @moduledoc """
  Responsible for consuming an acting upon any applicable
  events published by users of the `Events` application.
  """

  require Logger

  def init(_) do
    Events.subscribe(Events.CallRequested)
    Events.subscribe(Events.HangupRequested)
    Events.subscribe(Events.RemoveRequested)
    {:ok, nil}
  end

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def handle_info({:broadcast, event}, state) do
    Events.Handler.handle(event)
    {:noreply, state}
  end

  defimpl Events.Handler, for: Events.CallRequested do
    @spec handle(Events.CallRequested.t) :: any
    def handle(event) do
      url_prefix = Application.get_env(:callbacks, :webhook_url).()
      from = Application.get_env(:callbacks, :cli).()
      conference_status_callback = url_prefix <> Callbacks.Web.Router.Helpers.conference_status_changed_path(Callbacks.Web.Endpoint, :status_changed, event.conference)
      url = url_prefix <> Callbacks.Web.Router.Helpers.conference_call_answered_path(Callbacks.Web.Endpoint, :answered, event.conference, event.call, conference_status_callback: conference_status_callback)
      status_callback = url_prefix <> Callbacks.Web.Router.Helpers.conference_call_status_changed_path(Callbacks.Web.Endpoint, :status_changed, event.conference, event.call)
      result = Callbacks.Consumer.log_api_call(:call, fn ->
        Callbacks.Consumer.provider.call(
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
  end

  defimpl Events.Handler, for: Events.HangupRequested do
    @spec handle(Events.HangupRequested.t) :: any
    def handle(event) do
      Callbacks.Consumer.log_api_call(:hangup, fn ->
        Callbacks.Consumer.provider.hangup(event.providers_call_identifier)
       end)
    end
  end

  defimpl Events.Handler, for: Events.RemoveRequested do
    @spec handle(Events.RemoveRequested.t) :: any
    def handle(event) do
      Callbacks.Consumer.log_api_call(:kick, fn ->
        Callbacks.Consumer.provider.kick_participant_from_conference(event.providers_identifier, event.providers_call_identifier)
      end)
    end
  end

  @spec provider :: module
  def provider do
    Application.get_env(:callbacks, :provider)
  end

  @spec log_api_call(atom, (() -> Callbacks.Provider.result)) :: Callbacks.Provider.result
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
