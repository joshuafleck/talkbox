defmodule Callbacks.Provider do
  @moduledoc """
  This module defines the behaviour of a telephony provider. It allows for real
  providers to be replaced with fake providers during testing. It also allows
  for implementation with multiple telephony providers if that should be desired.
  """

  @type success :: {:ok, String.t}
  @type failure :: {:error, String.t, number}
  @type result :: success | failure
  @callback call(to: String.t, from: String.t, url: String.t, status_callback: String.t, status_callback_events: [String.t]) :: result
  @callback hangup(String.t) :: result
  @callback kick_participant_from_conference(String.t, String.t) :: result
end
