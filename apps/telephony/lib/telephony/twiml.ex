defmodule Telephony.Twiml do
  @moduledoc """
  Used for building TwiML responses to Twilio requests that provide instruction
  to Twilio for how to handle a call leg.

  See: https://www.twilio.com/docs/api/twiml
  """
  import ExTwiml

  # credo:disable-for-lines:8
  @doc ~S"""
  Places the call leg into the conference named with the provided conference identifier.

  ## Examples

    iex(1)> Telephony.Twiml.join_conference("conference_identifier", "http://test.com/conference_updated?a=b&b=c")
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?><Response><Dial><Conference beep=\"false\" statusCallback=\"http://test.com/conference_updated?a=b&amp;b=c\" statusCallbackEvent=\"start end join leave mute hold\">conference_identifier</Conference></Dial></Response>"
  """
  @spec join_conference(String.t, String.t | nil) :: String.t
  def join_conference(conference_identifier, status_callback \\ "") do
    twiml do
      dial do
        conference conference_identifier, beep: false, status_callback: status_callback, status_callback_event: "start end join leave mute hold"
      end
    end
  end
end
