defmodule Telephony.Callbacks do
  @moduledoc """
  Builds callback URLs for the telephony provider's webhooks
  """

  # TODO: use https://hexdocs.pm/elixir/URI.html#encode_query/1
  def chair_answered(conference) do
    webhook_url() <>
    "/chair_answered?" <>
    "conference=" <> conference.identifier <>
    "&chair=" <> conference.chair <>
    "&conference_status_callback=" <> URI.encode_www_form(conference_status_callback(conference))
  end

  def conference_status_callback(conference) do
    webhook_url() <>
    "/conference_status_changed?" <>
    "conference=" <> conference.identifier <>
    "&chair=" <> conference.chair
  end

  def chair_status_callback(conference) do
    webhook_url() <>
    "/chair_call_status_changed?" <>
    "conference=" <> conference.identifier <>
    "&chair=" <> conference.chair
  end

  def pending_participant_answered(conference) do
    webhook_url() <>
    "/pending_participant_answered?" <>
    "conference=" <> conference.identifier <>
    "&chair=" <> conference.chair <>
    "&pending_participant=" <> conference.pending_participant
  end

  def participant_status_callback(conference) do
    webhook_url() <>
    "/participant_call_status_changed?" <>
    "conference=" <> conference.identifier <>
    "&chair=" <> conference.chair <>
    "&participant=" <> conference.pending_participant
  end

  defp webhook_url do
    Telephony.get_env(:webhook_url) <> Telephony.get_env(:provider_callback_url_prefix)
  end
end
