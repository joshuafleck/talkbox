defmodule Events.PersistenceTest do
  use ExUnit.Case, async: false
  doctest Events.Persistence

  setup do
    Application.stop(:events)
    :ok = Application.start(:events)
    Logger.metadata(application: :events)
    Logger.configure(level: :info)
    on_exit fn ->
      Logger.metadata(application: nil)
      Logger.configure(level: :warn)
    end
  end

  test "ability to write events to file then have them read back" do
    event = %Events.UserRequestsCall{callee: "amy", user: "josh", conference: nil}
    assert Events.Persistence.write(event) == :ok
    Logger.flush
    events_file_path = Application.get_env(:events, :persistence_file_path)
    events = events_file_path
    |> Events.Persistence.read()
    |> Enum.map(&(&1))
    assert events == [event]
  end
end
