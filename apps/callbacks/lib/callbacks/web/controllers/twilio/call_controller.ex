defmodule Callbacks.Web.Twilio.CallController do
  @moduledoc """
  This controller is responsible for responding to requests from Twilio
  regarding the status of call legs.
  """
  use Callbacks.Web, :controller

  defmacrop failed_to_connect(status) do
    quote do: unquote(status) in ~w(busy canceled failed no-answer)
  end

  defmacrop progressing(status) do
    quote do: unquote(status) in ~w(queued ringing in-progress)
  end

  @doc """
  Called when Twilio would like a TwiML instruction for what to do with the
  call leg when it is answered. This will instruct Twilio to place the
  call into a conference.
  """
  def answered(conn, %{"conference_id" => conference, "conference_status_callback" => conference_status_callback}) do
    conn
    |> put_resp_content_type("text/xml")
    |> text(Callbacks.Twiml.join_conference(conference, conference_status_callback))
  end

  @doc """
  Called when Twilio informs us that the status of the call leg has changed.
  In the case that the call leg is progressing from `queued` to `ringing` or `ringing` to
  `in-progress` this will publish an event indicating that the call status has changed.
  """
  def status_changed(conn, %{
    "conference_id" => conference,
    "call_id" => call,
    "CallSid" => call_sid,
    "CallStatus" => status,
    "SequenceNumber" => sequence_number}) when progressing(status) do
    {:ok, _} = Events.publish(%Events.CallStatusChanged{
      conference: conference,
      providers_call_identifier: call_sid,
      call: call,
      status: status,
      sequence_number: String.to_integer(sequence_number)})
    conn
    |> put_resp_content_type("text/xml")
    |> text("ok")
  end

  @doc """
  Called when Twilio informs us that the status of the call leg has changed.
  In the case that the call has failed to connect, we publish an event indicating
  that the call has failed to join the conference.
  """
  def status_changed(conn, %{
    "conference_id" => conference,
    "call_id" => call,
    "CallSid" => call_sid,
    "CallStatus" => status})
  when failed_to_connect(status) do
    {:ok, _} = Events.publish(%Events.CallFailedToJoinConference{
      conference: conference,
      providers_call_identifier: call_sid,
      call: call,
      reason: status})
    conn
    |> put_resp_content_type("text/xml")
    |> text("ok")
  end

  @doc """
  Called when Twilio informs us that the status of the call leg has changed.
  This is the catch-call case which will simply respond 'ok' and has no side effects.
  Necessary because we do not care about all of the `completed` call statuses.
  """
  def status_changed(conn, _params) do
    conn
    |> put_resp_content_type("text/xml")
    |> text("ok")
  end
end
