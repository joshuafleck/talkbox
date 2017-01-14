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

  def add_participant_to_conference(chair, participant) do
    conference = Telephony.Conference.create(chair, participant)
    conference
    |> call_chair(participant)
  end

  defp call_chair(conference, participant) do
    {:ok, _call} = get_env(:provider).call(
        to: conference.chair,
        from: get_env(:cli),
        url: Telephony.Callbacks.chair_answered(conference, participant))
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
