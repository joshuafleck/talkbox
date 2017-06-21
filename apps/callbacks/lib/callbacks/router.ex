defmodule Callbacks.Router do
  use GenServer
  @moduledoc """
  Responsible for consuming an acting upon any applicable
  events published by users of the `Events` application.
  """

  def init(_) do
    Events.Registry.subscribe(Events.CallRequested)
    Events.Registry.subscribe(Events.HangupRequested)
    Events.Registry.subscribe(Events.RemoveRequested)
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
      result = Application.get_env(:callbacks, :provider).call(
        to: event.destination,
        from: Application.get_env(:callbacks, :cli).(),
        url: url_prefix <> Callbacks.Web.Router.Helpers.conference_call_answered_path(Callbacks.Web.Endpoint, :answered, event.conference, event.call, conference_status_callback: url_prefix <> Callbacks.Web.Router.Helpers.conference_status_changed_path(Callbacks.Web.Endpoint, :status_changed, event.conference)),
        status_callback: url_prefix <> Callbacks.Web.Router.Helpers.conference_call_status_changed_path(Callbacks.Web.Endpoint, :status_changed, event.conference, event.call),
        status_callback_events: ~w(initiated ringing answered completed))
      case result do
        {:error, message, _} ->
          IO.puts("--------- CALL REQUEST FAILED WITH #{message}")
          {:error, message}
        result ->
          result
      end
    end
  end

  defimpl Events.Handler, for: Events.HangupRequested do
    @spec handle(Events.HangupRequested.t) :: any
    def handle(event) do
      result = Application.get_env(:callbacks, :provider).hangup(event.providers_call_identifier)
    end
  end

  defimpl Events.Handler, for: Events.RemoveRequested do
    @spec handle(Events.RemoveRequested.t) :: any
    def handle(event) do
      result = Application.get_env(:callbacks, :provider).kick_participant_from_conference(event.providers_identifier, event.providers_call_identifier)
    end
  end
end
