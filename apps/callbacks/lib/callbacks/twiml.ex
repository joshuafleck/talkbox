defmodule Callbacks.Twiml do
  import ExTwiml

  def join_conference(conference_identifier, status_callback \\ "") do
    twiml do
      dial do
        conference conference_identifier, beep: false, status_callback: xml_safe(status_callback), status_callback_event: "start end join leave mute hold"
      end
    end
  end

  defp xml_safe(uri) do
    uri
    |> String.replace("&", "&amp;")
  end
end
