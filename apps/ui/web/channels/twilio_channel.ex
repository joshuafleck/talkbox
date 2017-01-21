defmodule Ui.TwilioChannel do
  use Ui.Web, :channel

  def join("twilio:" <> client_name, payload, socket) do
    if authorized?(payload) do
      send self(), {:after_join, client_name}
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info({:after_join, client_name}, socket) do
    token = generate_token(client_name)
    push socket, "set_token", %{token: token}
    {:noreply, socket}
  end

  def handle_info(:after_update, socket) do
    # broadcast socket, "set_seats", %{seats: all_seats}
    {:noreply, socket}
  end

  def handle_in("start_call", %{"callee" => callee, "caller" => user}, socket) do
    Events.publish(%Events.UserRequestsCall{user: user, callee: callee})
    {:reply, {:ok, %{sid: "call.sid", status: "call.status", callee: "call.to"}}, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (seat:lobby).
  def handle_in("shout", payload, socket) do
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end

  defp generate_token(client_name) do
    ExTwilio.Capability.new
    |> ExTwilio.Capability.allow_client_incoming(client_name)
    |> ExTwilio.Capability.token
  end
end
