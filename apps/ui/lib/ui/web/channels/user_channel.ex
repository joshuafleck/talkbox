defmodule Ui.Web.UserChannel do
  @moduledoc """
  Channel through which we communicate with the SPA. Given messages
  from the client, will translate those into events published with the
  `Events` module.
  """
  use Ui.Web, :channel

  @doc """
  Called when the SPA is initially loaded, each client has its own channel
  named with the pattern: `user:<client name>`
  """
  def join("user:" <> client_name, payload, socket) do
    if authorized?(payload) do
      # TODO: check if this client already has an existing conference
      send self(), {:after_join, client_name}
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @doc """
  Generares a Twilio capability token allowing the client to interact with
  the configured Twilio application
  """
  def handle_info({:after_join, client_name}, socket) do
    token = generate_token(client_name)
    push socket, "set_token", %{token: token}
    {:noreply, socket}
  end

  def handle_info(:after_update, socket) do
    # broadcast socket, "event", %{<payload>}
    {:noreply, socket}
  end

  def handle_in("start_call", %{"callee" => callee, "user" => user, "conference" => conference}, socket) do
    :ok = Events.publish(%Events.UserRequestsCall{user: user, callee: callee, conference: conference})
    {:reply, {:ok, %{}}, socket}
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
    # TODO: implement authorisation
    true
  end

  defp generate_token(client_name) do
    ExTwilio.Capability.new
    |> ExTwilio.Capability.allow_client_incoming(client_name)
    |> ExTwilio.Capability.token
  end
end
