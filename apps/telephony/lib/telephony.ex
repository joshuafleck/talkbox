defmodule Telephony do
  @moduledoc """
  Documentation for Telephony.
  """
  require Logger

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
    # TODO: this should set the sid for the chair's call if it has not already been set
    call_sid = initiate_call_to_pending_participant(conference)
    # NOTE: this could fail if the participant has already been promoted (unlikely but possible)
    Telephony.Conference.set_call_sid_on_pending_participant(chair, conference_identifier, conference.pending_participant.identifier, call_sid)
  end

  def remove_conference(chair: chair, conference: conference_identifier) do
    Telephony.Conference.remove(chair, conference_identifier)
  end

  def remove_pending_participant(
        chair: chair,
        conference: conference_identifier,
        pending_participant: pending_participant) do
    %{participants: participants, chair: %{call_sid: call_sid}} = Telephony.Conference.remove_pending_participant(chair, conference_identifier, pending_participant)
    unless Enum.count(participants) > 0 do
      remove_conference(chair: chair, conference: conference_identifier)
      unless call_sid == nil do
        # Note: rather than hangup the chair, we could remove him from the conference (but it depends on having the conference sid set)
        get_env(:provider).hangup(call_sid)
      else
        # NOTE: this is unlikely but possible if this call is made before the chair's sid could be set
        Logger.warn "#{__MODULE__} unable to hangup chair's leg due to missing call sid for conference: #{conference_identifier}"
      end
    end
  end

  def hangup_pending_participant(
        chair: chair,
        conference: conference_identifier,
        pending_participant: pending_participant) do
      %{pending_participant: %{call_sid: call_sid}} = Telephony.Conference.fetch_by_pending_participant(chair, conference_identifier, pending_participant)
      unless call_sid == nil do
        get_env(:provider).hangup(call_sid)
      else
        # NOTE: this is unlikely but possible if this call is made before the participant's sid could be set
        Logger.warn "#{__MODULE__} unable to hangup pending participant's leg due to missing call sid for conference: #{conference_identifier}"
      end
      # NOTE: we'll receive a call status update event when the participant's call ends, which will trigger the actual removal of the participant
  end

  def add_participant(chair: chair, conference: conference_identifier, participant: participant) do
    Telephony.Conference.add_pending_participant(chair, conference_identifier, participant)
    call_pending_participant(chair: chair, conference: conference_identifier)
  end

  def promote_pending_participant(
        chair: chair,
        conference: conference_identifier,
        pending_participant: pending_participant) do
    # TODO: This should attempt to set the participant's call sid if it hasn't already been set
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
