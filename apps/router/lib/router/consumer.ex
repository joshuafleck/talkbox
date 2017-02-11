defmodule Router.Consumer do
  @moduledoc """
  Responsible for consuming events from the event queue
  and sending them off to be processed. Intended to run
  as a pool of workers to support scaling up when there
  is a high volume of events.
  """
  require Logger

  def start_link do
    Task.start_link(fn -> poll() end)
  end

  defp poll do
    case Events.consume do
      {:ok, event} ->
        Logger.debug "#{__MODULE__} consuming #{inspect(event)}"
        try do
          Router.Routing.routing(event)
        rescue
          error ->
            Logger.error "#{__MODULE__} error consuming #{inspect(event)}"
            Logger.error Exception.message(error)
            Logger.error Exception.format_stacktrace(System.stacktrace())
        end
      {:error, "queue is empty"} ->
        nil
    end
    :ok = :timer.sleep(10)
    poll()
  end
end
