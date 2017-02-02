defmodule Callbacks.Twilio.CallController do
  use Callbacks.Web, :controller

  defmacro failed_to_connect(status) do
    quote do: unquote(status) in ~w(busy canceled failed no-answer)
  end

  defmacro completed(status) do
    quote do: unquote(status) in ~w(completed)
  end

  defmacro progressing(status) do
    quote do: unquote(status) in ~w(queued ringing in-progress)
  end

  def chair_answered(conn, %{"conference" => conference, "conference_status_callback" => conference_status_callback}) do
    conn
    |> put_resp_content_type("text/xml")
    |> text(Callbacks.Twiml.join_conference(conference, conference_status_callback))
  end

  def chair_status_changed(conn, %{"conference" => conference, "chair" => chair, "CallSid" => call_sid, "CallStatus" => status}) when failed_to_connect(status) do
    Events.publish(%Events.ChairFailedToJoinConference{conference: conference, chair: chair, call_sid: call_sid, reason: status})
    conn
    |> put_resp_content_type("text/xml")
    |> text("ok")
  end

  def chair_status_changed(conn, _params) do
    # NOTE: Don't remove conference when chair call is completed - chair may have dropped off and wants to rejoin
    conn
    |> put_resp_content_type("text/xml")
    |> text("ok")
  end

  def pending_participant_answered(conn, %{"conference" => conference}) do
    conn
    |> put_resp_content_type("text/xml")
    |> text(Callbacks.Twiml.join_conference(conference))
  end

  def participant_status_changed(conn, %{"conference" => conference, "chair" => chair, "CallSid" => call_sid, "participant" => pending_participant, "CallStatus" => status, "SequenceNumber" => sequence_number}) when progressing(status) do
    Events.publish(%Events.PendingParticipantCallStatusChanged{conference: conference, chair: chair, call_sid: call_sid, pending_participant: pending_participant, call_status: status, sequence_number: String.to_integer(sequence_number)})
    conn
    |> put_resp_content_type("text/xml")
    |> text("ok")
  end

  def participant_status_changed(conn, %{"conference" => conference, "chair" => chair, "CallSid" => call_sid, "participant" => pending_participant, "CallStatus" => status}) when failed_to_connect(status) do
    Events.publish(%Events.PendingParticipantFailedToJoinConference{conference: conference, chair: chair, call_sid: call_sid, pending_participant: pending_participant, reason: status})
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
