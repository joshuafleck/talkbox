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
    Telephony.Conference.set_call_sid_on_chair(chair, conference.identifier, call_sid)
  end

  def call_pending_participant(chair: chair, conference: conference_identifier) do
    conference = Telephony.Conference.fetch(chair, conference_identifier)
    call_sid = initiate_call_to_pending_participant(conference)
    Telephony.Conference.set_call_sid_on_pending_participant(chair, conference_identifier, call_sid)
  end

  def remove_conference(chair: chair, conference: conference_identifier) do
    Telephony.Conference.remove(chair, conference_identifier)
  end

  def remove_pending_participant(
        chair: chair,
        conference: conference_identifier,
        pending_participant: pending_participant) do
    conference = Telephony.Conference.remove_pending_participant(chair, conference_identifier, pending_participant)
    unless Enum.count(conference.participants) > 0 do
      remove_conference(chair: chair, conference: conference_identifier)
      # TODO: what if the call sid has yet to be set on the chair??
      # TODO: rather than hangup the chair, can/should we just remove him from the conference??
      get_env(:provider).hangup(conference.chair.call_sid)
    end
  end

  def hangup_pending_participant(
        chair: chair,
        conference: conference_identifier,
        pending_participant: pending_participant) do
      conference = Telephony.Conference.fetch(chair, conference_identifier, pending_participant)
      # TODO: what if the call sid has yet to be set on the pending participant??
      get_env(:provider).hangup(conference.pending_participant.call_sid)
      # NOTE: we'll receive a call status update event when the participant leaves, which will trigger the actual removal of the participant
  end

  def add_participant(chair: chair, conference: conference_identifier, participant: participant) do
    Telephony.Conference.add_pending_participant(chair, conference_identifier, participant)
    call_pending_participant(chair: chair, conference: conference_identifier)
  end

  def promote_pending_participant(
        chair: chair,
        conference: conference_identifier,
        pending_participant: pending_participant) do
    Telephony.Conference.promote_pending_participant(chair, conference_identifier, pending_participant)
  end

  def update_call_status_of_pending_participant(
        chair: chair,
        conference: conference_identifier,
        pending_participant: pending_participant,
        call_status: call_status,
        sequence_number: sequence_number) do
    Telephony.Conference.update_call_status_of_pending_participant(chair, conference_identifier, pending_participant, call_status, sequence_number)
  end

  defp initiate_call_to_chair(conference) do
    get_env(:provider).call(
      to: conference.chair.identifier,
      from: get_env(:cli),
      url: Telephony.Callbacks.chair_answered(conference),
      status_callback: Telephony.Callbacks.chair_status_callback(conference),
      status_callback_events: ~w(completed))
  end

  defp initiate_call_to_pending_participant(conference) do
    get_env(:provider).call(
      to: conference.pending_participant.identifier,
      from: get_env(:cli),
      url: Telephony.Callbacks.pending_participant_answered(conference),
      status_callback: Telephony.Callbacks.participant_status_callback(conference),
      status_callback_events: ~w(initiated ringing completed))
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
