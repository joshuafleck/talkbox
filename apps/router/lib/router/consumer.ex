defmodule Router.Consumer do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], [])
  end

  @queue       "talkbox_routing"
  @queue_error "#{@queue}_error"

  def init(_opts) do
    {:ok, conn} = AMQP.Connection.open
    {:ok, chan} = AMQP.Channel.open(conn)
    AMQP.Basic.qos(chan, prefetch_count: 1)
    AMQP.Queue.declare(chan, @queue_error, durable: true)
    # Messages that cannot be delivered to any consumer in the main queue will be routed to the error queue
    AMQP.Queue.declare(chan, @queue, durable: true,
                                arguments: [{"x-dead-letter-exchange", :longstr, ""},
                                            {"x-dead-letter-routing-key", :longstr, @queue_error}])
    # Register the GenServer process as a consumer
    {:ok, _consumer_tag} = AMQP.Basic.consume(chan, @queue)
    {:ok, chan}
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: _}}, chan) do
    {:noreply, chan}
  end

  # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, %{consumer_tag: _}}, chan) do
    {:stop, :normal, chan}
  end

  # Confirmation sent by the broker to the consumer process after a Basic.cancel
  def handle_info({:basic_cancel_ok, %{consumer_tag: _}}, chan) do
    {:noreply, chan}
  end

  def handle_info({:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered}}, chan) do
    spawn fn -> consume(chan, tag, redelivered, payload) end
    {:noreply, chan}
  end

  defp consume(channel, tag, redelivered, payload) do
    try do
      number = String.to_integer(payload)
      if number <= 10 do
        AMQP.Basic.ack channel, tag
        IO.puts "Consumed a #{number}."
      else
        AMQP.Basic.reject channel, tag, requeue: false
        IO.puts "#{number} is too big and was rejected."
      end
    rescue
      _ ->
        # Requeue unless it's a redelivered message.
        # This means we will retry consuming a message once in case of exception
        # before we give up and have it moved to the error queue
        AMQP.Basic.reject channel, tag, requeue: not redelivered
        IO.puts "Error converting #{payload} to integer"
    end
  end
end
