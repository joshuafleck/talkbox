defmodule EventsTest do
  use ExUnit.Case, async: false
  doctest Events

  setup do
    Application.stop(:events)
    :ok = Application.start(:events)
  end
end
