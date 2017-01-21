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
    call_sid = get_env(:provider).call(
        to: conference.pending_participant.identifier,
        from: get_env(:cli),
        url: Telephony.Callbacks.pending_participant_answered(conference),
        status_callback: Telephony.Callbacks.participant_status_callback(conference),
        status_callback_events: ~w(initiated ringing completed))
    Telephony.Conference.update(conference.chair.identifier, fn conference -> {conference, %{conference | pending_participant: %{conference.pending_participant | call_sid: call_sid}}} end)
  end

  defp call_chair(conference) do
    call_sid = get_env(:provider).call(
        to: conference.chair.identifier,
        from: get_env(:cli),
        url: Telephony.Callbacks.chair_answered(conference),
        status_callback: Telephony.Callbacks.chair_status_callback(conference),
        status_callback_events: ~w(completed))
    Telephony.Conference.update(conference.chair.identifier, fn conference -> {conference, %{conference | chair: %{conference.chair | call_sid: call_sid}}} end)
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
