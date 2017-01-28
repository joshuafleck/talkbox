defmodule Telephony.Callbacks do
  @moduledoc """
  Builds callback URLs for the telephony provider's webhooks
  """

  def chair_answered(conference) do
    build_call_callback_url("chair_answered", %{
      conference: conference.identifier,
      chair: conference.chair.identifier,
      conference_status_callback: conference_status_callback(conference)
    })
  end

  def conference_status_callback(conference) do
    build_conference_callback_url("status_changed", %{
      conference: conference.identifier,
      chair: conference.chair.identifier
    })
  end

  def chair_status_callback(conference) do
    build_call_callback_url("chair_status_changed", %{
      conference: conference.identifier,
      chair: conference.chair.identifier
    })
  end

  def pending_participant_answered(conference) do
    build_call_callback_url("pending_participant_answered", %{
      conference: conference.identifier,
      chair: conference.chair.identifier,
      pending_participant: conference.pending_participant.identifier
    })
  end

  def participant_status_callback(conference) do
    build_call_callback_url("participant_status_changed", %{
      conference: conference.identifier,
      chair: conference.chair.identifier,
      participant: conference.pending_participant.identifier
    })
  end

  defp build_conference_callback_url(endpoint, parameters), do: build_url("conference/" <> endpoint, parameters)
  defp build_call_callback_url(endpoint, parameters), do: build_url("call/" <> endpoint, parameters)

  defp build_url(endpoint, parameters) do
    url = URI.parse(Telephony.get_env(:webhook_url))
    url
    |> Map.put(:path, "#{Telephony.get_env(:provider_callback_url_prefix)}/#{endpoint}")
    |> Map.put(:query, URI.encode_query(parameters))
    |> URI.to_string()
  end
end
