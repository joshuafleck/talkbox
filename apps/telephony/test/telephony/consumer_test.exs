defmodule Telephony.ConsumerTest do
  use ExUnit.Case, async: false

  setup do
    {:ok, _} = Telephony.Provider.Test.start_link
    Events.Persistence.init
    Logger.metadata(application: :events)
    Logger.configure(level: :info)
    on_exit fn ->
      Logger.metadata(application: nil)
      Logger.configure(level: :warn)
    end
  end

  test "ability to make a call" do
    event = %Events.CallRequested{destination: "destination_number", conference: "conference_identifier", call: "call_identifier"}
    Telephony.Consumer.handle(event)
    assert Telephony.Provider.Test.calls_received == [call:
                                                      [
                                                        to: "destination_number",
                                                        from: "+440000000000",
                                                        url: "http://test.com/telephony/twilio/conferences/conference_identifier/calls/call_identifier/answered?conference_status_callback=http%3A%2F%2Ftest.com%2Ftelephony%2Ftwilio%2Fconferences%2Fconference_identifier%2Fstatus_changed",
                                                        status_callback: "http://test.com/telephony/twilio/conferences/conference_identifier/calls/call_identifier/status_changed",
                                                        status_callback_events: ["initiated", "ringing", "answered", "completed"]]]
    assert Events.Persistence.published() == []
  end

  test "when the call cannot be dialled" do
    event = %Events.CallRequested{destination: "error", conference: "conference_identifier", call: "call_identifier"}
    Telephony.Consumer.handle(event)
    assert Telephony.Provider.Test.calls_received == [call:
                                                      [
                                                        to: "error",
                                                        from: "+440000000000",
                                                        url: "http://test.com/telephony/twilio/conferences/conference_identifier/calls/call_identifier/answered?conference_status_callback=http%3A%2F%2Ftest.com%2Ftelephony%2Ftwilio%2Fconferences%2Fconference_identifier%2Fstatus_changed",
                                                        status_callback: "http://test.com/telephony/twilio/conferences/conference_identifier/calls/call_identifier/status_changed",
                                                        status_callback_events: ["initiated", "ringing", "answered", "completed"]]]
    assert Events.Persistence.published() == [%Events.CallRequestFailed{call: "call_identifier", conference: "conference_identifier"}]
  end

  test "ability to hangup a call" do
    event = %Events.HangupRequested{conference: "conference_identifier", call: "call_identifier", providers_call_identifier: "call_sid"}
    Telephony.Consumer.handle(event)
    assert Telephony.Provider.Test.calls_received == [hangup: "call_sid"]
    assert Events.Persistence.published() == []
  end

  test "ability to remove a call" do
    event = %Events.RemoveRequested{conference: "conference_identifier", providers_identifier: "conference_sid", call: "call_identifier", providers_call_identifier: "call_sid"}
    Telephony.Consumer.handle(event)
    assert Telephony.Provider.Test.calls_received == [kick_participant_from_conference: "call_sid"]
    assert Events.Persistence.published() == []
  end
end
