defmodule Callbacks.TwilioControllerTest do
  use Callbacks.ConnCase

  test "POST /chair_answered", %{conn: conn} do
    conn = post conn, "/callbacks/twilio/chair_answered", %{
      "conference" => "conference_ident",
      "participant" => "participant_name"
    }
    assert response(conn, 200) =~ "<?xml version=\"1.0\" encoding=\"UTF-8\"?><Response><Dial><Conference>conference_ident</Conference></Dial></Response>"
  end
end
