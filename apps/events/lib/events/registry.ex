defmodule Events.Registry do
  @moduledoc """
  Provides the ability to subscribe to and to
  publish events.
  """

  @doc """
  Subscribe for events of a given topic
  """
  @spec subscribe(atom) :: :ok
  def subscribe(topic) do
    {:ok, _} = Registry.register(__MODULE__, topic, [])
    :ok
  end

  @doc """
  Publish an event on a given topic
  """
  @spec publish(any) :: :ok
  def publish(event) do
    Registry.dispatch(__MODULE__, event.__struct__, fn entries ->
      for {pid, _} <- entries, do: send(pid, {:broadcast, event})
    end)
  end
end
