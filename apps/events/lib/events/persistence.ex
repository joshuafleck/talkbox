defmodule Events.Persistence do
  @moduledoc """
  Provide the ability to persist an event stream to file
  such that events can be replayed in the future.
  """
  require Logger

  @doc """
  Initializes the output file
  """
  @spec init :: any
  def init do
    path = Application.get_env(:events, :persistence_file_path)
    File.rm(path)
    backend = {LoggerFileBackend, :events}
    Logger.add_backend(backend)
    Logger.configure_backend(backend,
      path: path,
      level: :info,
      format: "$message\n",
      metadata_filter: [application: :events])
  end

  @doc """
  Writes the event to file
  """
  @spec write(any) :: :ok | {:error, String.t}
  def write(event) do
    Logger.info fn ->
      Events.Event.serialize(event)
    end
  end

  @doc """
  Reads the event stream from file and loads it into the
  event queue.
  """
  @spec read(String.t) :: []
  def read(path) do
    path
    |> File.stream!()
    |> Stream.map(&Events.Event.deserialize(&1))
    |> Enum.map(&Events.Queue.put(&1))
  end
end
