defmodule TelephonyWeb.Twilio.ConferenceControllerTest do
  use TelephonyWeb.ConnCase, async: false

  setup do
    Events.Persistence.init
    Logger.metadata(application: :events)
    Logger.configure(level: :info)
    on_exit fn ->
      Logger.metadata(application: nil)
      Logger.configure(level: :warn)
    end
  end

  test "POST /telephony/twilio/conferences/2/status_changed when a participant has joined", %{conn: conn} do
    conn = post conn, "/telephony/twilio/conferences/2/status_changed", %{
      "CallSid" => "call_sid",
      "ConferenceSid" => "conference_sid",
      "StatusCallbackEvent" => "participant-join"
    }
    assert response(conn, 200) =~ "ok"
    assert Enum.take(Events.Persistence.published, 1) == [%Events.CallJoinedConference{conference: "2", providers_call_identifier: "call_sid", providers_identifier: "conference_sid"}]
  end

  test "POST /telephony/twilio/conferences/2/status_changed when a participant has left", %{conn: conn} do
    conn = post conn, "/telephony/twilio/conferences/2/status_changed", %{
      "CallSid" => "call_sid",
      "ConferenceSid" => "conference_sid",
      "StatusCallbackEvent" => "participant-leave"
    }
    assert response(conn, 200) =~ "ok"
    assert Enum.take(Events.Persistence.published, 1) == [%Events.CallLeftConference{conference: "2", providers_call_identifier: "call_sid", providers_identifier: "conference_sid"}]
  end

  test "POST /telephony/twilio/conferences/2/status_changed when the conference has ended", %{conn: conn} do
    conn = post conn, "/telephony/twilio/conferences/2/status_changed", %{
      "ConferenceSid" => "conference_sid",
      "StatusCallbackEvent" => "conference-end"
    }
    assert response(conn, 200) =~ "ok"
    assert Enum.take(Events.Persistence.published, 1) == [%Events.ConferenceEnded{conference: "2", providers_identifier: "conference_sid"}]
  end

  test "POST /telephony/twilio/conferences/2/status_changed for any other event", %{conn: conn} do
    conn = post conn, "/telephony/twilio/conferences/2/status_changed", %{
      "StatusCallbackEvent" => "anthing"
    }
    assert response(conn, 200) =~ "ok"
    assert Events.Persistence.published == []
  end
end
