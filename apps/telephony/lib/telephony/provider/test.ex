defmodule Telephony.Provider.Test do
  @moduledoc """
  Provides telephony provider behaviour without making any real calls
  """
  @behaviour Telephony.Provider

  @doc """
  Simulates initiation of a phone call.
  The `to` argument will be returned as the call_sid.
  Pass a value of `error` as the `to` argument to simulate an error from the telephony provider
  """
  def call(
    to: to,
    from: _from,
    url: _url,
    status_callback: _status_callback,
    status_callback_events: _status_callback_events
  ) do
    case to do
      "error" ->
        {:error, "call initiation failed", 500}
      _ ->
        {:ok, to}
    end
  end

  @doc """
  Simulates hang up of a phone call.
  The `call_sid` argument will be returned as the call_sid.
  Pass a value of `error` as the `call_sid` argument to simulate an error from the telephony provider
  """
  def hangup(call_sid) do
    case call_sid do
      "error" ->
        {:error, "hangup failed", 500}
      _ ->
        {:ok, call_sid}
    end
  end

  @doc """
  Simulates removal of participant from a conference.
  The `call_sid` argument will be returned as the call_sid.
  Pass a value of `error` as the `call_sid` argument to simulate an error from the telephony provider
  """
  def kick_participant_from_conference(_conference_sid, call_sid) do
    case call_sid do
      "error" ->
        {:error, "kick from conference failed", 500}
      _ ->
        {:ok, call_sid}
    end
  end
end
