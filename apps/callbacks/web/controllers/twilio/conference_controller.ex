defmodule Callbacks.Twilio.ConferenceController do
  use Callbacks.Web, :controller

  defmacro participant_joined(event) do
    quote do: unquote(event) in ~w(participant-join)
  end

  defmacro participant_left(event) do
    quote do: unquote(event) in ~w(participant-leave)
  end

  defmacro conference_ended(event) do
    quote do: unquote(event) in ~w(conference-end)
  end

  # TODO: Need to capture the conference sid (when the chair joins) so we can manipulate the conference
  # TODO: Need to capture when participants leave so we can update our cached view of the conference
  # TODO: Need to capture when the conference ends so that we can clear our cached view of the conference
  def status_changed(conn, %{"conference" => conference, "chair" => chair, "ConferenceSid" => conference_sid, "CallSid" => call_sid, "StatusCallbackEvent" => event}) when participant_joined(event) do
    Events.publish(%Events.ParticipantJoinedConference{conference: conference, chair: chair, call_sid: call_sid, conference_sid: conference_sid})
    conn
    |> put_resp_content_type("text/xml")
    |> text("ok")
  end

  def status_changed(conn, %{"conference" => conference, "chair" => chair, "ConferenceSid" => conference_sid, "CallSid" => call_sid, "StatusCallbackEvent" => event}) when participant_left(event) do
    Events.publish(%Events.ParticipantLeftConference{conference: conference, chair: chair, call_sid: call_sid, conference_sid: conference_sid})
    conn
    |> put_resp_content_type("text/xml")
    |> text("ok")
  end

  def status_changed(conn, %{"conference" => conference, "chair" => chair, "ConferenceSid" => conference_sid, "StatusCallbackEvent" => event}) when conference_ended(event) do
    Events.publish(%Events.ConferenceEnded{conference: conference, chair: chair, conference_sid: conference_sid})
    conn
    |> put_resp_content_type("text/xml")
    |> text("ok")
  end

  def status_changed(conn, _params) do
    conn
    |> put_resp_content_type("text/xml")
    |> text("ok")
  end
end
