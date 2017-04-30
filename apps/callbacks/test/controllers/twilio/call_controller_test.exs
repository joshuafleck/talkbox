defmodule Callbacks.Web.Twilio.CallControllerTest do
  use Callbacks.Web.ConnCase, async: false

  setup do
    Application.stop(:events)
    :ok = Application.start(:events)
  end

  test "POST /callbacks/twilio/call/chair_answered", %{conn: conn} do
    conn = post conn, "/callbacks/twilio/call/chair_answered", %{
      "conference" => "conference_ident",
      "conference_status_callback" => "callback_url"
    }
    assert response(conn, 200) =~ "<?xml version=\"1.0\" encoding=\"UTF-8\"?><Response><Dial><Conference beep=\"false\" statusCallback=\"callback_url\" " <>
      "statusCallbackEvent=\"start end join leave mute hold\">conference_ident</Conference></Dial></Response>"
    assert Events.consume == {:error, "queue is empty"}
  end

  test "POST /callbacks/twilio/call/chair_status_changed", %{conn: conn} do
    conn = post conn, "/callbacks/twilio/call/chair_status_changed", %{
      "conference" => "conference_ident",
      "chair" => "chair_name",
      "CallSid" => "call_sid",
      "CallStatus" => "no-answer"
    }
    assert response(conn, 200) =~ "ok"
    assert Events.consume == {:ok, %Events.ChairFailedToJoinConference{call_sid: "call_sid", chair: "chair_name", conference: "conference_ident", reason: "no-answer"}}
  end

  test "POST /callbacks/twilio/call/chair_status_changed when the call status is not recognised", %{conn: conn} do
    conn = post conn, "/callbacks/twilio/call/chair_status_changed", %{
      "CallStatus" => "anything"
    }
    assert response(conn, 200) =~ "ok"
    assert Events.consume == {:error, "queue is empty"}
  end

  test "POST /callbacks/twilio/call/pending_participant_answered", %{conn: conn} do
    conn = post conn, "/callbacks/twilio/call/pending_participant_answered", %{
      "conference" => "conference_ident"
    }
    assert response(conn, 200) =~ "<?xml version=\"1.0\" encoding=\"UTF-8\"?><Response><Dial><Conference beep=\"false\" statusCallback=\"\" " <>
      "statusCallbackEvent=\"start end join leave mute hold\">conference_ident</Conference></Dial></Response>"
    assert Events.consume == {:error, "queue is empty"}
  end

  test "POST /callbacks/twilio/call/participant_status_changed", %{conn: conn} do
    conn = post conn, "/callbacks/twilio/call/participant_status_changed", %{
      "conference" => "conference_ident",
      "chair" => "chair_name",
      "CallSid" => "call_sid",
      "CallStatus" => "ringing",
      "participant" => "participant_name",
      "SequenceNumber" => "0"
    }
    assert response(conn, 200) =~ "ok"
    assert Events.consume == {:ok, %Events.PendingParticipantCallStatusChanged{
      call_sid: "call_sid", call_status: "ringing", chair: "chair_name", conference: "conference_ident", pending_participant: "participant_name", sequence_number: 0}}
  end

  test "POST /callbacks/twilio/call/participant_status_changed when the call has failed", %{conn: conn} do
    conn = post conn, "/callbacks/twilio/call/participant_status_changed", %{
      "conference" => "conference_ident",
      "chair" => "chair_name",
      "CallSid" => "call_sid",
      "CallStatus" => "no-answer",
      "participant" => "participant_name",
      "SequenceNumber" => "0"
    }
    assert response(conn, 200) =~ "ok"
    assert Events.consume == {:ok, %Events.PendingParticipantFailedToJoinConference{
      call_sid: "call_sid", chair: "chair_name", conference: "conference_ident", pending_participant: "participant_name", reason: "no-answer"}}
  end

  test "POST /callbacks/twilio/call/participant_status_changed when the call status is not recognised", %{conn: conn} do
    conn = post conn, "/callbacks/twilio/call/participant_status_changed", %{
      "CallStatus" => "anything"
    }
    assert response(conn, 200) =~ "ok"
    assert Events.consume == {:error, "queue is empty"}
  end
end
