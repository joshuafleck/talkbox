defmodule Telephony.Callbacks do
  @moduledoc """
  Builds callback URLs for the telephony provider's webhooks
  """

  def chair_answered(conference, participant) do
    webhook_url() <>
    "/chair_answered?" <>
    "conference=" <> conference.identifier <>
    "&participant=" <> participant
  end

  defp webhook_url do
    Telephony.get_env(:webhook_url) <> "/callbacks"
  end
end
