defmodule Events.Persistence do
  @moduledoc """
  Provide the ability to persist an event stream to file
  such that events can be replayed in the future.
  """
  require Logger

  @doc """
  Initializes the output file. Removes any previously existing file.
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

  ## Examples

  iex(1)> Events.Persistence.write(%Events.UserRequestsCall{user: "user", callee: "callee", conference: nil})
  :ok
  """
  @spec write(Events.t) :: :ok | {:error, String.t}
  def write(event) do
    Logger.info fn ->
      Events.Event.serialize(event)
    end
  end

  @doc """
  Reads the event stream from file
  """
  @spec read(String.t) :: Enumerable.t
  def read(path) do
    path
    |> File.stream!()
    |> Stream.map(&Events.Event.deserialize(&1))
  end
end
