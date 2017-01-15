defmodule Telephony.Callbacks do
  @moduledoc """
  Builds callback URLs for the telephony provider's webhooks
  """

  def chair_answered(conference) do
    webhook_url() <>
    "/chair_answered?" <>
    "conference=" <> conference.identifier <>
    "&chair=" <> conference.chair
  end

  defp webhook_url do
    Telephony.get_env(:webhook_url) <> Telephony.get_env(:provider_callback_url_prefix)
  end
end
