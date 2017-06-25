defmodule Telephony.Web.Twilio.ConferenceControllerTest do
  use Telephony.Web.ConnCase, async: false

  setup do
    Application.stop(:events)
    :ok = Application.start(:events)
  end

  test "POST /telephony/twilio/conference/status_changed when a participant has joined", %{conn: conn} do
    conn = post conn, "/telephony/twilio/conference/status_changed", %{
      "conference" => "conference_ident",
      "chair" => "chair_name",
      "CallSid" => "call_sid",
      "ConferenceSid" => "conference_sid",
      "StatusCallbackEvent" => "participant-join"
    }
    assert response(conn, 200) =~ "ok"
    assert Events.consume == {:ok, %Events.ParticipantJoinedConference{call_sid: "call_sid", chair: "chair_name", conference: "conference_ident", conference_sid: "conference_sid"}}
  end

  test "POST /telephony/twilio/conference/status_changed when a participant has left", %{conn: conn} do
    conn = post conn, "/telephony/twilio/conference/status_changed", %{
      "conference" => "conference_ident",
      "chair" => "chair_name",
      "CallSid" => "call_sid",
      "ConferenceSid" => "conference_sid",
      "StatusCallbackEvent" => "participant-leave"
    }
    assert response(conn, 200) =~ "ok"
    assert Events.consume == {:ok, %Events.ParticipantLeftConference{call_sid: "call_sid", chair: "chair_name", conference: "conference_ident", conference_sid: "conference_sid"}}
  end

  test "POST /telephony/twilio/conference/status_changed when the conference has ended", %{conn: conn} do
    conn = post conn, "/telephony/twilio/conference/status_changed", %{
      "conference" => "conference_ident",
      "chair" => "chair_name",
      "ConferenceSid" => "conference_sid",
      "StatusCallbackEvent" => "conference-end"
    }
    assert response(conn, 200) =~ "ok"
    assert Events.consume == {:ok, %Events.ConferenceEnded{chair: "chair_name", conference: "conference_ident", conference_sid: "conference_sid"}}
  end

  test "POST /telephony/twilio/conference/status_changed for any other event", %{conn: conn} do
    conn = post conn, "/telephony/twilio/conference/status_changed", %{
      "StatusCallbackEvent" => "anthing"
    }
    assert response(conn, 200) =~ "ok"
    assert Events.consume == {:error, "queue is empty"}
  end
end
