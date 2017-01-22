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
    call_sid = initiate_call_to_chair(conference)
    set_call_sid_on_chair(call_sid, conference)
  end

  def call_pending_participant(chair: chair, conference: conference) do
    conference = find_conference(chair, conference)
    call_sid = initiate_call_to_pending_participant(conference)
    set_call_sid_on_pending_participant(call_sid, conference)
  end

  def find_and_remove_conference(chair: chair, conference: conference) do
    conference = find_conference(chair, conference)
    remove_conference(conference)
  end

  def find_and_remove_pending_participant(
        chair: chair,
        conference: conference,
        pending_participant: pending_participant) do
    conference = find_conference_with_pending_participant(chair, conference, pending_participant)
    remove_pending_participant(conference)
    # TODO: End the chair's call if there are no other participants. Also, remove the conference (depends if we receive a conference-end update)??
    # TODO: There is a slight possibility that because the find/remove are in separate steps that something could change in between
  end

  def find_and_promote_pending_participant(
        chair: chair,
        conference: conference,
        pending_participant: pending_participant) do
    conference = find_conference_with_pending_participant(chair, conference, pending_participant)
    promote_pending_participant(conference)
    # TODO: There is a slight possibility that because the find/promote are in separate steps that something could change in between
  end

  def find_and_update_call_status_of_pending_participant(
        chair: chair,
        conference: conference,
        pending_participant: pending_participant,
        call_status: call_status,
        sequence_number: sequence_number) do
    conference = find_conference_with_pending_participant(chair, conference, pending_participant)
    if elem(conference.pending_participant.call_status, 1) < sequence_number do
      update_call_status_of_pending_participant(conference, call_status, sequence_number)
    end
    # TODO: There is a slight possibility that because the find/update are in separate steps that something could change in between
  end

  defp initiate_call_to_chair(conference) do
    get_env(:provider).call(
      to: conference.chair.identifier,
      from: get_env(:cli),
      url: Telephony.Callbacks.chair_answered(conference),
      status_callback: Telephony.Callbacks.chair_status_callback(conference),
      status_callback_events: ~w(completed))
  end

  defp find_conference(chair, conference) do
    %{identifier: ^conference} = Telephony.Conference.get(chair)
  end

  defp find_conference_with_pending_participant(chair, conference, pending_participant) do
    %{pending_participant: %{identifier: ^pending_participant}} = find_conference(chair, conference)
  end

  defp initiate_call_to_pending_participant(conference) do
    get_env(:provider).call(
      to: conference.pending_participant.identifier,
      from: get_env(:cli),
      url: Telephony.Callbacks.pending_participant_answered(conference),
      status_callback: Telephony.Callbacks.participant_status_callback(conference),
      status_callback_events: ~w(initiated ringing completed))
  end

  # TODO: move these definitions to conference module?
  defp set_call_sid_on_pending_participant(call_sid, conference) do
    Telephony.Conference.update(conference.chair.identifier, fn conference -> {conference, %{conference | pending_participant: %{conference.pending_participant | call_sid: call_sid}}} end)
  end

  defp set_call_sid_on_chair(call_sid, conference) do
    Telephony.Conference.update(conference.chair.identifier, fn conference -> {conference, %{conference | chair: %{conference.chair | call_sid: call_sid}}} end)
  end

  defp remove_conference(conference) do
    Telephony.Conference.update(conference.chair.identifier, fn _ -> :pop end)
  end

  defp remove_pending_participant(conference) do
    Telephony.Conference.update(conference.chair.identifier, fn conference -> {conference, %{conference | pending_participant: nil}} end)
  end

  defp promote_pending_participant(conference) do
    Telephony.Conference.update(conference.chair.identifier, fn conference -> {conference, %{conference | pending_participant: nil, participants: conference.participants ++ conference.pending_participant}} end)
  end

  defp update_call_status_of_pending_participant(conference, call_status, sequence_number) do
    Telephony.Conference.update(conference.chair.identifier, fn conference -> {conference, %{conference | pending_participant: %{conference.pending_participant | call_status: {call_status, sequence_number}}}} end)
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
