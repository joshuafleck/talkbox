defmodule Telephony.Provider do
  @callback call(%{to: String.t, from: String.t, url: String.t, status_callback: String.t, status_callback_events: [String.t]}) :: {:ok, String.t} | {:error, String.t, number}
  @callback hangup(String.t) :: {:ok, String.t} | {:error, String.t, number}
  @callback kick_participant_from_conference(String.t, String.t) :: {:ok, String.t} | {:error, String.t, number}
end
