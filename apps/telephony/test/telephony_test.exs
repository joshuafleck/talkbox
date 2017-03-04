defmodule TelephonyTest do
  use ExUnit.Case, async: false
  doctest Telephony

  setup do
    Application.stop(:telephony)
    :ok = Application.start(:telephony)
    {:ok, conference} = Telephony.initiate_conference("chair", "participant")
    {:ok, conference: conference}
  end

  test "initiate_conference returns a conference with the call_sid set on the chair" do
    {:ok, conference} = Telephony.initiate_conference("new_chair", "participant")
    # Initiates the chairs's call leg
    assert conference.chair.call_sid == "new_chair"
  end

  test "initiate_conference when the chair's call initiation fails raises an error" do
    assert Telephony.initiate_conference("error", "participant") == {:error, "call initiation failed", nil}
  end

  test "call_or_promote_pending_participant when the participant's call_sid belongs to the chair", %{conference: conference} do
    assert conference.pending_participant.call_sid == nil
    assert conference.sid == nil

    {:ok, conference} = join_chair_to_conference(conference)

    # Does not change the chair's call sid
    assert conference.chair.call_sid == "chair"
    # Initiates the participant's call leg
    assert conference.pending_participant.call_sid == "participant"
    # Sets the conference sid
    assert conference.sid == "conference_sid"
  end

  test "call_or_promote_pending_participant when the participant's call_sid does not match the chair's", %{conference: conference} do
    assert_raise MatchError, ~r(call_sid already set), fn ->
      join_to_conference(participant_reference(conference, "different_call_sid"))
    end
  end

  test "call_or_promote_pending_participant when the initiation of the call to the pending participant fails" do
    {:ok, conference} = Telephony.initiate_conference("different_chair", "error")
    assert conference.pending_participant != nil

    {:error, _message, conference} = join_to_conference(participant_reference(conference, "different_chair"))

    # Clears the pending participant
    assert conference.pending_participant == nil
    # Removes the conference
    assert Telephony.remove_conference(Telephony.Conference.reference(conference)) == nil
  end

  test "call_or_promote_pending_participant when the participant's call_sid belongs to the pending participant", %{conference: conference} do
    {:ok, conference} = join_chair_to_conference(conference)
    assert conference.pending_participant != nil
    assert Map.get(conference.participants, "participant") == nil

    {:ok, conference} = join_participant_to_conference(conference)

    # Removes the pending participant
    assert conference.pending_participant == nil
    # Adds a fully-fledged participant
    participant = Map.get(conference.participants, "participant")
    assert participant != nil
    # Does not change the participant's call sid
    assert participant.call_sid == "participant"
  end

  test "call_or_promote_pending_participant when the participant's call_sid does not match the pending participant's", %{conference: conference} do
    {:ok, conference} = join_chair_to_conference(conference)
    assert_raise MatchError, ~r(call_sid already set), fn ->
      join_to_conference(participant_reference(conference, "different_call_sid"))
    end
  end

  test "remove_chair_or_participant when the call_sid matches the chair's", %{conference: conference} do
    {:ok, conference} = join_chair_to_conference(conference)
    assert conference.chair.call_sid == "chair"

    conference = Telephony.remove_chair_or_participant(chairs_participant_reference(conference))

    # Unsets the chair's call sid
    assert conference.chair.call_sid == nil
    # Does not remove the conference
    assert Telephony.remove_conference(Telephony.Conference.reference(conference)) != nil
  end

  test "remove_chair_or_participant when the call_sid matches the participant's", %{conference: conference} do
    conference = join_chair_and_pending_participant(conference)
    participant = Map.get(conference.participants, "participant")
    assert participant != nil
    assert participant.call_sid == "participant"

    conference = Telephony.remove_chair_or_participant(participants_participant_reference(conference))

    # Removes the participant from the conference
    participant = Map.get(conference.participants, "participant")
    assert participant == nil
    # Removes the conference
    assert Telephony.remove_conference(Telephony.Conference.reference(conference)) == nil
  end

  test "remove_chair_or_participant when the conference has already been removed", %{conference: conference} do
    Telephony.remove_conference(Telephony.Conference.reference(conference))

    conference = Telephony.remove_chair_or_participant(chairs_participant_reference(conference))

    # Returns nil, but does not raise
    assert conference == nil
  end

  test "remove conference", %{conference: conference} do
    conference = Telephony.remove_conference(Telephony.Conference.reference(conference))

    # Returns the conference
    assert conference != nil
  end

  test "remove conference when the conference has already been removed", %{conference: conference} do
    Telephony.remove_conference(Telephony.Conference.reference(conference))

    conference = Telephony.remove_conference(Telephony.Conference.reference(conference))

    # Returns nil, but does not raise
    assert conference == nil
  end

  test "remove_pending_participant", %{conference: conference} do
    assert conference.pending_participant != nil

    conference = Telephony.remove_pending_participant(pending_participant_reference(conference))

    # Removes the pending participant
    assert conference.pending_participant == nil
    # Removes the conference
    assert Telephony.remove_conference(Telephony.Conference.reference(conference)) == nil
  end

  test "remove_pending_participant when there is an existing participant", %{conference: conference} do
    reference = pending_participant_reference(conference)
    join_chair_and_pending_participant(conference)
    {:ok, conference} = Telephony.add_participant(reference)
    assert conference.pending_participant != nil
    assert Map.get(conference.participants, "participant") != nil

    conference = Telephony.remove_pending_participant(pending_participant_reference(conference))

    # Removes the pending participant
    assert conference.pending_participant == nil
    # Does not remove the conference
    assert Telephony.remove_conference(Telephony.Conference.reference(conference)) != nil
  end

  test "remove_pending_participant when there is no pending participant", %{conference: conference} do
    reference = pending_participant_reference(conference)
    conference = Telephony.remove_pending_participant(reference)
    assert conference.pending_participant == nil

    assert_raise MatchError, ~r(matching conference not found), fn ->
      Telephony.remove_pending_participant(reference)
    end
  end

  test "hangup_pending_participant", %{conference: conference} do
    assert conference.pending_participant != nil

    conference = Telephony.hangup_pending_participant(pending_participant_reference(conference))

    # Returns the conference
    assert conference != nil
  end

  test "add_participant", %{conference: conference} do
    reference = pending_participant_reference(conference)
    conference = join_chair_and_pending_participant(conference)
    assert conference.pending_participant == nil

    {:ok, conference} = Telephony.add_participant(reference)

    # Creates a pending participant
    assert conference.pending_participant != nil
    # Sets the call_sid on the pending participant
    assert conference.pending_participant.call_sid == "participant"
  end

  test "hangup_participant", %{conference: conference} do
    conference = join_chair_and_pending_participant(conference)

    result = Telephony.hangup_participant(participants_participant_reference(conference))

    # It kicks the participant from the conference
    assert result == {:ok, "participant"}
  end

  test "add_participant when there is already a pending participant", %{conference: conference} do
    assert conference.pending_participant != nil

    assert_raise MatchError, ~r(pending participant already set), fn ->
      Telephony.add_participant(pending_participant_reference(conference))
    end
  end

  test "update_call_status_of_pending_participant", %{conference: conference} do
    assert conference.pending_participant.call_status == {nil, -1}

    conference = Telephony.update_call_status_of_pending_participant(pending_participant_reference(conference), "ringing", 1)

    # Updates the call status
    assert conference.pending_participant.call_status == {"ringing", 1}
  end

  defp join_chair_to_conference(conference), do: join_to_conference(chairs_participant_reference(conference))
  defp join_participant_to_conference(conference), do: join_to_conference(participants_participant_reference(conference))
  defp join_to_conference(reference), do: Telephony.call_or_promote_pending_participant(reference)
  defp chairs_participant_reference(conference), do: participant_reference(conference, "chair")
  defp participants_participant_reference(conference), do: participant_reference(conference, "participant")
  defp participant_reference(conference, call_sid) do
    %Telephony.Conference.ParticipantReference{
      chair: conference.chair.identifier,
      identifier: conference.identifier,
      conference_sid: "conference_sid",
      participant_call_sid: call_sid
    }
  end
  defp pending_participant_reference(conference) do
    %Telephony.Conference.PendingParticipantReference{
      chair: conference.chair.identifier,
      identifier: conference.identifier,
      pending_participant_identifier: conference.pending_participant.identifier
    }
  end
  defp join_chair_and_pending_participant(conference) do
    {:ok, conference} = join_chair_to_conference(conference)
    {:ok, conference} = join_participant_to_conference(conference)
    conference
  end
end
