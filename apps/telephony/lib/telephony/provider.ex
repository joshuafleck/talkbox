defmodule Telephony.Provider do
  @moduledoc """
  This module defines the behaviour of a telephony provider. It allows for real
  providers to be replaced with fake providers during testing. It also allows
  for implementation with multiple telephony providers if that should be desired.
  """
  @callback call(%{to: String.t, from: String.t, url: String.t, status_callback: String.t, status_callback_events: [String.t]}) :: {:ok, String.t} | {:error, String.t, number}
  @callback hangup(String.t) :: {:ok, String.t} | {:error, String.t, number}
  @callback kick_participant_from_conference(String.t, String.t) :: {:ok, String.t} | {:error, String.t, number}
end
