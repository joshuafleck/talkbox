defmodule Telephony do
  @moduledoc """
  Documentation for Telephony.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Telephony.hello
      :world

  """
  def hello do
    :world
  end

  def initiate_conference(chair: chair, participant: participant) do
    conference = Telephony.Conference.create(chair, participant)
    conference
    |> call_chair()
  end

  def call_pending_participant(chair: chair, conference: conference) do
    conference = %{identifier: ^conference} = Telephony.Conference.get(chair)
    {:ok, _call} = get_env(:provider).call(
        to: conference.pending_participant,
        from: get_env(:cli),
        url: Telephony.Callbacks.pending_participant_answered(conference))
  end

  defp call_chair(conference) do
    {:ok, _call} = get_env(:provider).call(
        to: conference.chair,
        from: get_env(:cli),
        url: Telephony.Callbacks.chair_answered(conference))
  end

  def get_env(name) do
    setting = Application.get_env(:telephony, name)
    if is_function(setting) do
      setting.()
    else
      setting
    end
  end
end
