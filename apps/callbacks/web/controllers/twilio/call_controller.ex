defmodule Callbacks.Twilio.CallController do
  @moduledoc """
  This controller is responsible for responding to requests from Twilio
  regarding the status of call legs.
  """
  use Callbacks.Web, :controller

  @doc """
  Given a call status from Twilio, returns true if the
  status indicates that the call leg failed to connect.
  """
  defmacro failed_to_connect(status) do
    quote do: unquote(status) in ~w(busy canceled failed no-answer)
  end

  @doc """
  Given a call status from Twilio, returns true if the
  status indicates that the call leg is progressing towards
  connection.
  """
  defmacro progressing(status) do
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

  def chair_status_changed(conn, _params) do
    conn
    |> put_resp_content_type("text/xml")
    |> text("ok")
  end

  def pending_participant_answered(conn, %{"conference" => conference}) do
    conn
    |> put_resp_content_type("text/xml")
    |> text(Callbacks.Twiml.join_conference(conference))
  end

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

  # TODO: is it possible for the participant leg to connect without actually entering the conference? If so, we should send an event upon the participant's leg completion
  def participant_status_changed(conn, _params) do
    conn
    |> put_resp_content_type("text/xml")
    |> text("ok")
  end
end
