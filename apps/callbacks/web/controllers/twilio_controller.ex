defmodule Callbacks.TwilioController do
  use Callbacks.Web, :controller

  def chair_answered(conn, %{"conference" => conference, "chair" => chair}) do
    Events.publish(%Events.ChairJoiningConference{conference: conference, chair: chair})

    conn
    |> put_resp_content_type("text/xml")
    |> text(Callbacks.Twiml.join_conference(conference))
  end

  def pending_participant_answered(conn, %{"conference" => conference, "chair" => chair, "pending_participant" => pending_participant}) do
    Events.publish(%Events.PendingParticipantJoiningConference{conference: conference, chair: chair, pending_participant: pending_participant})

    conn
    |> put_resp_content_type("text/xml")
    |> text(Callbacks.Twiml.join_conference(conference))
  end
end
