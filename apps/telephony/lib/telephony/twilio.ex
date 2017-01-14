defmodule Telephony.Twilio do
  @moduledoc """
  Twilio-specific telephony implementation
  """

  def call(to: to, from: from, url: url) do
    ExTwilio.Call.create([
      {:to, to},
      {:from, from},
      {:url, url}])
  end
end
