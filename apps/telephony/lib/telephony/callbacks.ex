defmodule Telephony.Callbacks do
  @moduledoc """
  Builders of callback URLs for the telephony provider's webhooks.
  These callbacks feed into the `Callbacks` application - you can
  see how they are routed by looking at the `Callbacks.Router` module.
  """

  @doc """
  This is the URL that will be called when the chairperson
  answers their call leg.

  ## Examples

      iex(1)> %Telephony.Conference.Reference{
      ...(1)>   identifier: "test_conference",
      ...(1)>   chair: "test_chair",
      ...(1)> } |> Telephony.Callbacks.chair_answered()
      "http://test.com/callbacks/twilio/call/chair_answered?chair=test_chair&conference=test_conference&conference_status_callback=http%3A%2F%2Ftest.com%2Fcallbacks%2Ftwilio%2Fconference%2Fstatus_changed%3Fchair%3Dtest_chair%26conference%3Dtest_conference"
  """
  @spec call_answered(Telephony.Conference.internal_identifier, Telephony.Conference.internal_identifier) :: String.t
  def call_answered(conference_identifier, call_identifier) do
    build_call_callback_url("answered", conference_identifier, call_identifier, %{
      conference_status_callback: conference_status_callback(conference_identifier)
    })
  end

  @doc """
  This is the URL that will be called when the status of the conference changes.

  ## Examples

      iex(2)> %Telephony.Conference.Reference{
      ...(2)>   identifier: "test_conference",
      ...(2)>   chair: "test_chair",
      ...(2)> } |> Telephony.Callbacks.conference_status_callback()
      "http://test.com/callbacks/twilio/conference/status_changed?chair=test_chair&conference=test_conference"
  """
  @spec conference_status_callback(Telephony.Conference.internal_identifier) :: String.t
  def conference_status_callback(conference_identifier) do
    build_conference_callback_url("status_changed", conference_identifier, %{})
  end

  @doc """
  This is the URL that will be called when the status of the chairperson's call leg changes.

  ## Examples

      iex(3)> %Telephony.Conference.Reference{
      ...(3)>   identifier: "test_conference",
      ...(3)>   chair: "test_chair",
      ...(3)> } |> Telephony.Callbacks.chair_status_callback()
      "http://test.com/callbacks/twilio/call/chair_status_changed?chair=test_chair&conference=test_conference"
  """
  @spec call_status_updated(Telephony.Conference.internal_identifier, Telephony.Conference.internal_identifier) :: String.t
  def call_status_updated(conference_identifier, call_identifier) do
    build_call_callback_url("status_changed", conference_identifier, call_identifier, %{})
  end

  @spec build_conference_callback_url(String.t, Telephony.Conference.identifier, map) :: String.t
  defp build_conference_callback_url(endpoint, conference_identifier, parameters), do: build_url("conferences/#{conference_identifier}/#{endpoint}", parameters)

  @spec build_call_callback_url(String.t, Telephony.Conference.internal_identifier, Telephony.Conference.internal_identifier, map) :: String.t
  defp build_call_callback_url(endpoint, conference_identifier, call_identifier, parameters), do: build_url("conferences/#{conference_identifier}/calls/#{call_identifier}/#{endpoint}", parameters)

  @spec build_url(String.t, map) :: String.t
  defp build_url(endpoint, parameters) do
    url = URI.parse(Telephony.get_env(:webhook_url))
    url
    |> Map.put(:path, "#{Telephony.get_env(:provider_callback_url_prefix)}/#{endpoint}")
    |> Map.put(:query, URI.encode_query(parameters))
    |> URI.to_string()
  end
end
