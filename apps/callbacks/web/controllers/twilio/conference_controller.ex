defmodule Callbacks.Twilio.ConferenceController do
  use Callbacks.Web, :controller

  def status_changed(conn, %{"conference" => conference, "chair" => chair, "StatusCallbackEvent" => event}) do
    # TODO: Need to capture the conference sid (when the chair joins) so we can manipulate the conference
    # TODO: Need to capture when participants leave so we can update our cached view of the conference
    # TODO: Need to capture when the conference ends so that we can clear our cached view of the conference
    conn
    |> put_resp_content_type("text/xml")
    |> text("ok")
  end
end
