defmodule Telephony.Twilio do
  @moduledoc """
  Twilio-specific telephony implementation
  """
  require Logger

  def call(to: to, from: from, url: url) do
    Logger.debug "#{__MODULE__} calling #{to} from #{from} on #{url}"
    ExTwilio.Call.create([
      {:to, format_if_client(to)},
      {:from, from},
      {:url, url}])
  end

  defp format_if_client(to) do
    if Regex.match?(~r/\+\d+/, to) do
      to
    else
      "client:" <> to
    end
  end
end
