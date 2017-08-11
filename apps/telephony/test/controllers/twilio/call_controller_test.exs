defmodule TelephonyWeb.Twilio.CallControllerTest do
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

  test "POST /telephony/twilio/conferences/2/calls/0/answered", %{conn: conn} do
    conn = post conn, "/telephony/twilio/conferences/2/calls/0/answered", %{
      "conference_status_callback" => "callback_url"
    }
    assert response(conn, 200) =~ ~s(<?xml version="1.0" encoding="UTF-8"?><Response><Dial><Conference beep="false" statusCallback="callback_url" ) <>
      ~s(statusCallbackEvent="start end join leave mute hold">2</Conference></Dial></Response>)
    assert Events.Persistence.published == []
  end

  test "POST /telephony/twilio/conferences/2/calls/0/status_changed", %{conn: conn} do
    conn = post conn, "/telephony/twilio/conferences/2/calls/0/status_changed", %{
      "CallSid" => "call_sid",
      "CallStatus" => "ringing",
      "SequenceNumber" => "0"
    }
    assert response(conn, 200) =~ "ok"
    assert Enum.take(Events.Persistence.published, 1) == [%Events.CallStatusChanged{call: "0", conference: "2", providers_call_identifier: "call_sid", sequence_number: 0, status: "ringing"}]
  end

  test "POST /telephony/twilio/conferences/2/calls/0/status_changed when the call has failed", %{conn: conn} do
    conn = post conn, "/telephony/twilio/conferences/2/calls/0/status_changed", %{
      "CallSid" => "call_sid",
      "CallStatus" => "no-answer",
      "SequenceNumber" => "0"
    }
    assert response(conn, 200) =~ "ok"
    assert Enum.take(Events.Persistence.published, 1) == [%Events.CallFailedToJoinConference{call: "0", conference: "2", providers_call_identifier: "call_sid", reason: "no-answer"}]
  end

  test "POST /telephony/twilio/conferences/2/calls/0/status_changed when the call status is not recognised", %{conn: conn} do
    conn = post conn, "/telephony/twilio/conferences/2/calls/0/status_changed", %{
      "CallStatus" => "anything"
    }
    assert response(conn, 200) =~ "ok"
    assert Events.Persistence.published == []
  end
end
