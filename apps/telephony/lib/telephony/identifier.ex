defmodule Telephony.Identifier do
  @moduledoc """
  Provides the ability to generate deterministic
  identifiers.
  """

  @type t :: String.t

  def start_link do
    Agent.start_link(fn -> 0 end, name: __MODULE__)
  end

  @doc """
  Gets the next identifier from the sequence
  """
  @spec get_next() :: t
  def get_next do
    Agent.get_and_update(__MODULE__, fn previous ->
      {Integer.to_string(previous), previous + 1}
    end)
  end
end
