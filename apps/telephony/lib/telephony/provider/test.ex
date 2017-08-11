defmodule Telephony.Provider.Test do
  @moduledoc """
  Provides telephony provider behaviour without making any real calls. Records the calls made and their arguments such that the tests can verify the correct arguments were passed to the provider.
  """
  @behaviour Telephony.Provider

  def start_link do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def calls_received do
    Agent.get(__MODULE__, &(&1))
  end

  @doc """
  Simulates initiation of a phone call.
  The `to` argument will be returned as the call_sid.
  Pass a value of `error` as the `to` argument to simulate an error from the telephony provider
  """
  def call(opts) do
    record_call(:call, opts)
    case opts[:to] do
      "error" ->
        {:error, "call initiation failed", 500}
      _ ->
        {:ok, opts[:to]}
    end
  end

  @doc """
  Simulates hang up of a phone call.
  The `call_sid` argument will be returned as the call_sid.
  Pass a value of `error` as the `call_sid` argument to simulate an error from the telephony provider
  """
  def hangup(call_sid) do
    record_call(:hangup, call_sid)
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
    record_call(:kick_participant_from_conference, call_sid)
    case call_sid do
      "error" ->
        {:error, "kick from conference failed", 500}
      _ ->
        {:ok, call_sid}
    end
  end

  @spec record_call(atom, any) :: any
  defp record_call(name, arguments) do
    Agent.update(__MODULE__, &List.insert_at(&1, -1, {name, arguments}))
  end
end
