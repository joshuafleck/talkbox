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
  chair's call leg when it is answered. This will instruct Twilio to place the
  chair into a conference.
  """
  def chair_answered(conn, %{"conference" => conference, "conference_status_callback" => conference_status_callback}) do
    conn
    |> put_resp_content_type("text/xml")
    |> text(Callbacks.Twiml.join_conference(conference, conference_status_callback))
  end

  @doc """
  Called when Twilio informs us that the status of the chair's call leg has changed.
  In the case that the call has failed to connect, we publish an event indicating
  that the chair has failed to join the conference.
  """
  def chair_status_changed(conn, %{"conference" => conference, "chair" => chair, "CallSid" => call_sid, "CallStatus" => status}) when failed_to_connect(status) do
    {:ok, _} = Events.publish(%Events.ChairFailedToJoinConference{conference: conference, chair: chair, call_sid: call_sid, reason: status})
    conn
    |> put_resp_content_type("text/xml")
    |> text("ok")
  end

  @doc """
  Called when Twilio informs us that the status of the chair's call leg has changed.
  This is the catch-call case which will simply respond 'ok' and has no side effects.
  Necessary because we do not care about all of the `completed` call statuses.
  """
  def chair_status_changed(conn, _params) do
    conn
    |> put_resp_content_type("text/xml")
    |> text("ok")
  end

  @doc """
  Called when Twilio would like a TwiML instruction for what to do with the
  pending participant's call leg when it is answered. This will instruct Twilio to place the
  pending participant into a conference.
  """
  def pending_participant_answered(conn, %{"conference" => conference}) do
    conn
    |> put_resp_content_type("text/xml")
    |> text(Callbacks.Twiml.join_conference(conference))
  end

  @doc """
  Called when Twilio informs us that the status of the participant's call leg has changed.
  In the case that the call leg is progressing from `queued` to `ringing` or `ringing` to
  `in-progress` this will publish an event indicating that the call status has changed.
  """
  def participant_status_changed(conn, %{
    "conference" => conference,
    "chair" => chair,
    "CallSid" => call_sid,
    "participant" => pending_participant,
    "CallStatus" => status,
    "SequenceNumber" => sequence_number}) when progressing(status) do
    {:ok, _} = Events.publish(%Events.PendingParticipantCallStatusChanged{
      conference: conference,
      chair: chair,
      call_sid: call_sid,
      pending_participant: pending_participant,
      call_status: status,
      sequence_number: String.to_integer(sequence_number)})
    conn
    |> put_resp_content_type("text/xml")
    |> text("ok")
  end

  @doc """
  Called when Twilio informs us that the status of the participant's call leg has changed.
  In the case that the call has failed to connect, we publish an event indicating
  that the pending participant has failed to join the conference.
  """
  def participant_status_changed(conn, %{
    "conference" => conference,
    "chair" => chair,
    "CallSid" => call_sid,
    "participant" => pending_participant,
    "CallStatus" => status}) when failed_to_connect(status) do
    {:ok, _} = Events.publish(%Events.PendingParticipantFailedToJoinConference{
      conference: conference,
      chair: chair,
      call_sid: call_sid,
      pending_participant: pending_participant,
      reason: status})
    conn
    |> put_resp_content_type("text/xml")
    |> text("ok")
  end

  @doc """
  Called when Twilio informs us that the status of the participant's call leg has changed.
  This is the catch-call case which will simply respond 'ok' and has no side effects.
  Necessary because we do not care about all of the `completed` call statuses.
  """
  def participant_status_changed(conn, _params) do
    conn
    |> put_resp_content_type("text/xml")
    |> text("ok")
  end
end
