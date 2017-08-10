defmodule ContactCentreWeb.ConferenceChannel do
  @moduledoc """
  Channel through which we communicate with the SPA once a conference has
  been initiated. Communication on this channel will continue until the
  conference has ended.
  """
  use ContactCentreWeb, :channel

  @doc """
  Called when a conference is started, each conference has its own channel
  named with the pattern: `conference:<conference identifier>`
  """
  def join("conference:" <> _conference_identifier, payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:after_update, socket) do
    # broadcast socket, "event", %{<payload>}
    {:noreply, socket}
  end

  def handle_in("request_to_remove_call", %{"conference" => conference, "call" => call}, socket) do
    :ok = Events.publish(%Events.ChairpersonRequestsToRemoveCall{
          conference: conference,
          call: call})
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
    true
  end
end
