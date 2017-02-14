defmodule Events.QueueTest do
  use ExUnit.Case, async: false
  doctest Events.Queue

  setup do
    Application.stop(:events)
    :ok = Application.start(:events)
  end
end
