defmodule Callbacks.TwilioController do
  use Callbacks.Web, :controller

  def chair_answered(conn, %{"conference" => conference, "participant" => participant}) do
    response = Callbacks.Twiml.join_conference(conference)

    conn
    |> put_resp_content_type("text/xml")
    |> text(response)
  end
end
