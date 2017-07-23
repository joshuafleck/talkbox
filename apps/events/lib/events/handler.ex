defmodule Events.Handler do
  @moduledoc """
  A `GenServer` for subscribing to and consuming events.
  Subscribe to the desired events and have them routed
  to custom event handler functions.

  ## Usage

      # Subscribes to the provided list of events
      @subscriptions [Events.CallRequested, ...]
      use Events.Handler

      # Implement a handler for each type of event
      def handle(event = %Events.CallRequest{}) do
        ...
      end
  """
  @callback handle(Events.t) :: any

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      use GenServer
      @behaviour Events.Handler

      def init(_) do
        Enum.each(@subscriptions, fn topic ->
          Events.subscribe(topic)
        end)
        {:ok, nil}
      end

      def handle_info({:broadcast, event}, state) do
        handle(event)
        {:noreply, state}
      end

      def start_link do
        GenServer.start_link(__MODULE__, nil, name: __MODULE__)
      end
    end
  end
end
