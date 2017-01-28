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

  def chair_answered(conn, %{"conference" => conference, "chair" => chair, "conference_status_callback" => conference_status_callback}) do
    Events.publish(%Events.ChairJoiningConference{conference: conference, chair: chair})
    conn
    |> put_resp_content_type("text/xml")
    |> text(Callbacks.Twiml.join_conference(conference, conference_status_callback))
  end

  def chair_status_changed(conn, %{"conference" => conference, "chair" => chair, "CallStatus" => status}) when failed_to_connect(status) do
    Events.publish(%Events.ChairFailedToJoinConference{conference: conference, chair: chair, reason: status})
    conn
    |> put_resp_content_type("text/xml")
    |> text("ok")
  end

  def chair_status_changed(conn, _params) do
    # NOT A TODO: Don't remove conference when chair call is completed - chair may have dropped off
    conn
    |> put_resp_content_type("text/xml")
    |> text("ok")
  end

  def pending_participant_answered(conn, %{"conference" => conference, "chair" => chair, "pending_participant" => pending_participant}) do
    Events.publish(%Events.PendingParticipantJoiningConference{conference: conference, chair: chair, pending_participant: pending_participant})
    conn
    |> put_resp_content_type("text/xml")
    |> text(Callbacks.Twiml.join_conference(conference))
  end

  def participant_status_changed(conn, %{"conference" => conference, "chair" => chair, "participant" => pending_participant, "CallStatus" => status, "SequenceNumber" => sequence_number}) when progressing(status) do
    Events.publish(%Events.PendingParticipantCallStatusChanged{conference: conference, chair: chair, pending_participant: pending_participant, call_status: status, sequence_number: String.to_integer(sequence_number)})
    conn
    |> put_resp_content_type("text/xml")
    |> text("ok")
  end

  def participant_status_changed(conn, %{"conference" => conference, "chair" => chair, "participant" => pending_participant, "CallStatus" => status}) when failed_to_connect(status) do
    Events.publish(%Events.PendingParticipantFailedToJoinConference{conference: conference, chair: chair, pending_participant: pending_participant, reason: status})
    conn
    |> put_resp_content_type("text/xml")
    |> text("ok")
  end

  def participant_status_changed(conn, _params) do
    conn
    |> put_resp_content_type("text/xml")
    |> text("ok")
  end
end
