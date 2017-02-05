defmodule Telephony.Callbacks do
  @moduledoc """
  Builders of callback URLs for the telephony provider's webhooks
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
  @spec chair_answered(Telephony.Conference.Reference.t) :: String.t
  def chair_answered(reference) do
    build_call_callback_url("chair_answered", %{
      conference: reference.identifier,
      chair: reference.chair,
      conference_status_callback: conference_status_callback(reference)
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
  @spec conference_status_callback(Telephony.Conference.Reference.t) :: String.t
  def conference_status_callback(reference) do
    build_conference_callback_url("status_changed", %{
      conference: reference.identifier,
      chair: reference.chair
    })
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
  @spec chair_status_callback(Telephony.Conference.Reference.t) :: String.t
  def chair_status_callback(reference) do
    build_call_callback_url("chair_status_changed", %{
      conference: reference.identifier,
      chair: reference.chair
    })
  end

  @doc """
  This is the URL that will be called when the pending participant
  answers their call leg.

  ## Examples

      iex(5)> %Telephony.Conference.PendingParticipantReference{
      ...(5)>   identifier: "test_conference",
      ...(5)>   chair: "test_chair",
      ...(5)>   pending_participant_identifier: "pending_participant_identifier"
      ...(5)> } |> Telephony.Callbacks.pending_participant_answered()
      "http://test.com/callbacks/twilio/call/pending_participant_answered?chair=test_chair&conference=test_conference&pending_participant=pending_participant_identifier"
  """
  @spec pending_participant_answered(Telephony.Conference.PendingParticipantReference.t) :: String.t
  def pending_participant_answered(pending_participant_reference) do
    build_call_callback_url("pending_participant_answered", %{
      conference: pending_participant_reference.identifier,
      chair: pending_participant_reference.chair,
      pending_participant: pending_participant_reference.pending_participant_identifier
    })
  end

  @doc """
  This is the URL that will be called when the status of the participant (or pending participant's)
  call leg changes.

  ## Examples

      iex(6)> %Telephony.Conference.PendingParticipantReference{
      ...(6)>   identifier: "test_conference",
      ...(6)>   chair: "test_chair",
      ...(6)>   pending_participant_identifier: "pending_participant_identifier"
      ...(6)> } |> Telephony.Callbacks.participant_status_callback()
      "http://test.com/callbacks/twilio/call/participant_status_changed?chair=test_chair&conference=test_conference&participant=pending_participant_identifier"
  """
  @spec participant_status_callback(Telephony.Conference.PendingParticipantReference.t) :: String.t
  def participant_status_callback(pending_participant_reference) do
    build_call_callback_url("participant_status_changed", %{
      conference: pending_participant_reference.identifier,
      chair: pending_participant_reference.chair,
      participant: pending_participant_reference.pending_participant_identifier
    })
  end

  @spec build_conference_callback_url(String.t, map) :: String.t
  defp build_conference_callback_url(endpoint, parameters), do: build_url("conference/" <> endpoint, parameters)

  @spec build_call_callback_url(String.t, map) :: String.t
  defp build_call_callback_url(endpoint, parameters), do: build_url("call/" <> endpoint, parameters)

  @spec build_url(String.t, map) :: String.t
  defp build_url(endpoint, parameters) do
    url = URI.parse(Telephony.get_env(:webhook_url))
    url
    |> Map.put(:path, "#{Telephony.get_env(:provider_callback_url_prefix)}/#{endpoint}")
    |> Map.put(:query, URI.encode_query(parameters))
    |> URI.to_string()
  end
end
