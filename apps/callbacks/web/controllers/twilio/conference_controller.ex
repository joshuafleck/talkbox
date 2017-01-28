defmodule Callbacks.Twilio.ConferenceController do
  use Callbacks.Web, :controller

  def status_changed(conn, %{"conference" => conference, "chair" => chair, "StatusCallbackEvent" => event}) do
    # TODO #Events.publish(%Events.ChairFailedToJoinConference{conference: conference, chair: chair, reason: call_status})
    conn
    |> put_resp_content_type("text/xml")
    |> text("ok")
  end
end
