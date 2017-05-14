defmodule Events.PersistenceTest do
  use ExUnit.Case, async: false

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

  test "ability to write events to file then have them read back into the queue" do
    assert Events.Queue.pop == {:error, "queue is empty"}
    event = %Events.UserRequestsCall{callee: "amy", user: "josh"}
    Events.Persistence.write(event)
    Logger.flush
    assert Events.Persistence.read(Application.get_env(:events, :persistence_file_path)) == [ok: %Events.UserRequestsCall{callee: "amy", user: "josh"}]
    assert Events.Queue.pop == {:ok, event}
  end
end
