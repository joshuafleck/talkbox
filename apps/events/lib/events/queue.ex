defmodule Events.Queue do
  @moduledoc """
  A FIFO queue, see:
  http://elixir-lang.org/getting-started/erlang-libraries.html#the-queue-module
  """
  use GenServer

  @doc """
  Starts a singleton GenServer
  """
  def start_link do
    GenServer.start_link(__MODULE__, :queue.new, name: __MODULE__)
  end

  @doc """
  Puts an event onto the queue

  ## Examples

    iex(8)> Events.Queue.put("test")
    {:ok, "test"}
  """
  def put(event) do
    GenServer.call(__MODULE__, {:put, event})
  end

  @doc """
  Pops the first item off of the queue

  ## Examples

    iex(8)> Events.Queue.put("test")
    {:ok, "test"}
    iex(9)> Events.Queue.pop()
    {:ok, "test"}

    iex(12)> Events.Queue.pop()
    {:error, "queue is empty"}
  """
  def pop do
    GenServer.call(__MODULE__, {:pop})
  end

  def handle_call({:put, event}, _from, queue) do
    {:reply, {:ok, event}, :queue.in(event, queue)}
  end

  def handle_call({:pop}, _from, queue) do
    {value, queue} = :queue.out(queue)
    case value do
      :empty ->
        {:reply, {:error, "queue is empty"}, queue}
      {:value, event} ->
        {:reply, {:ok, event}, queue}
      result ->
        {:reply, {:error, "unexepected result from queue: #{result}"}, queue}
    end
  end
end
