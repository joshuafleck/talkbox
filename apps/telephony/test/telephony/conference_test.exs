defmodule Telephony.ConferenceTest do
  use ExUnit.Case, async: true
  doctest Telephony.Conference

  setup do
    chairs_call_leg = %Telephony.Conference.Leg{call_sid: nil, call_status: {nil, -1}, identifier: "chair"}
    participants_call_leg = %Telephony.Conference.Leg{call_sid: nil, call_status: {nil, -1}, identifier: "participant"}
    conference = %Telephony.Conference{chair: chairs_call_leg, identifier: "identifier", participants: %{}, pending_participant: participants_call_leg, sid: nil}
    conferences = %{"chair" => conference}
    {:ok, conference: conference, conferences: conferences, chairs_call_leg: chairs_call_leg, participants_call_leg: participants_call_leg}
  end

  test "create when there is not an existing conference creates a conference" do
    {:reply, {:ok, conference}, conferences} = Telephony.Conference.handle_call({:create, "chair", "participant", "identifier"}, nil, %{})
    assert conference.identifier == "identifier"
    assert conference.chair.identifier == "chair"
    assert conference.pending_participant.identifier == "participant"
    assert conference == Map.get(conferences, "chair")
  end

  test "create when there is an existing conference returns an error", %{conferences: conferences} do
    {:reply, {:error, message}, ^conferences} = Telephony.Conference.handle_call({:create, "chair", "participant", "identifier"}, nil, conferences)
    assert message == "conference exists for chair"
  end

  test "set_call_sid_on_chair when the call_sid has not been set sets the call_sid on the chair", %{conferences: conferences, conference: conference} do
    assert conference.chair.call_sid == nil
    {:reply, {:ok, conference}, conferences} = Telephony.Conference.handle_call({:set_call_sid_on_chair, conference, "test_call_sid"}, nil, conferences)
    assert conference.chair.call_sid == "test_call_sid"
    assert Map.get(conferences, "chair") == conference
  end

  test "set_call_sid_on_chair when the call_sid has already been set does not change the call_sid on the chair" do
    conference = %Telephony.Conference{chair: %Telephony.Conference.Leg{call_sid: "test_call_sid", identifier: "chair"}, identifier: "identifier", pending_participant: nil}
    conferences = %{"chair" => conference}
    assert conference.chair.call_sid == "test_call_sid"
    {:reply, {:ok, ^conference}, ^conferences} = Telephony.Conference.handle_call({:set_call_sid_on_chair, conference, "test_call_sid"}, nil, conferences)
  end

  test "set_call_sid_on_chair when the call_sid has been set to a different call_sid returns an error" do
    conference = %Telephony.Conference{chair: %Telephony.Conference.Leg{call_sid: "test_call_sid", identifier: "chair"}, identifier: "identifier", pending_participant: nil}
    conferences = %{"chair" => conference}
    assert conference.chair.call_sid == "test_call_sid"
    {:reply, {:error, message}, ^conferences} = Telephony.Conference.handle_call({:set_call_sid_on_chair, conference, "different_test_call_sid"}, nil, conferences)
    assert message == "call_sid already set"
  end

  test "remove_call_sid_on_chair when the call_sid has not been set does not change the call_sid on the chair", %{conferences: conferences, conference: conference} do
    assert conference.chair.call_sid == nil
    {:reply, {:ok, ^conference}, ^conferences} = Telephony.Conference.handle_call({:remove_call_sid_on_chair, conference, "test_call_sid"}, nil, conferences)
  end

  test "remove_call_sid_on_chair when the call_sid matches the one that has been set removes the call_sid" do
    conference = %Telephony.Conference{chair: %Telephony.Conference.Leg{call_sid: "test_call_sid", identifier: "chair"}, identifier: "identifier", pending_participant: nil}
    conferences = %{"chair" => conference}
    assert conference.chair.call_sid == "test_call_sid"
    {:reply, {:ok, conference}, conferences} = Telephony.Conference.handle_call({:remove_call_sid_on_chair, conference, "test_call_sid"}, nil, conferences)
    assert conference.chair.call_sid == nil
    assert Map.get(conferences, "chair") == conference
  end

  test "remove_call_sid_on_chair when the call_sid has been set to a different call_sid returns an error" do
    conference = %Telephony.Conference{chair: %Telephony.Conference.Leg{call_sid: "test_call_sid", identifier: "chair"}, identifier: "identifier", pending_participant: nil}
    conferences = %{"chair" => conference}
    assert conference.chair.call_sid == "test_call_sid"
    {:reply, {:error, message}, ^conferences} = Telephony.Conference.handle_call({:remove_call_sid_on_chair, conference, "different_test_call_sid"}, nil, conferences)
    assert message == "call_sid does not match"
  end

  test "set_conference_sid when the conference_sid has not been set sets the conference_sid on the conference", %{conferences: conferences, conference: conference} do
    assert conference.sid == nil
    {:reply, {:ok, conference}, conferences} = Telephony.Conference.handle_call({:set_conference_sid, conference, "test_conference_sid"}, nil, conferences)
    assert conference.sid == "test_conference_sid"
    assert Map.get(conferences, "chair") == conference
  end

  test "set_conference_sid when the conference_sid has already been set does not change the conference_sid on the conference", %{chairs_call_leg: chairs_call_leg} do
    conference = %Telephony.Conference{sid: "test_conference_sid", chair: chairs_call_leg, identifier: "identifier", pending_participant: nil}
    conferences = %{"chair" => conference}
    assert conference.sid == "test_conference_sid"
    {:reply, {:ok, ^conference}, ^conferences} = Telephony.Conference.handle_call({:set_conference_sid, conference, "test_conference_sid"}, nil, conferences)
  end

  test "set_conference_sid when the conference_sid has been set to a different conference_sid returns an error", %{chairs_call_leg: chairs_call_leg} do
    conference = %Telephony.Conference{sid: "test_conference_sid", chair: chairs_call_leg, identifier: "identifier", pending_participant: nil}
    conferences = %{"chair" => conference}
    assert conference.sid == "test_conference_sid"
    {:reply, {:error, message}, ^conferences} = Telephony.Conference.handle_call({:set_conference_sid, conference, "different_test_conference_sid"}, nil, conferences)
    assert message == "conference_sid already set"
  end

  test "set_call_sid_on_pending_participant when the call_sid has not been set sets the call_sid on the pending participant", %{conferences: conferences, conference: conference} do
    assert conference.pending_participant.call_sid == nil
    {:reply, {:ok, conference}, conferences} = Telephony.Conference.handle_call({:set_call_sid_on_pending_participant, conference, "test_call_sid"}, nil, conferences)
    assert conference.pending_participant.call_sid == "test_call_sid"
    assert Map.get(conferences, "chair") == conference
  end

  test "set_call_sid_on_pending_participant when the call_sid has already been set does not change the call_sid on the pending participant", %{chairs_call_leg: chairs_call_leg} do
    conference = %Telephony.Conference{chair: chairs_call_leg, identifier: "identifier", pending_participant: %Telephony.Conference.Leg{call_sid: "test_call_sid", identifier: "participant"}}
    conferences = %{"chair" => conference}
    assert conference.pending_participant.call_sid == "test_call_sid"
    {:reply, {:ok, ^conference}, ^conferences} = Telephony.Conference.handle_call({:set_call_sid_on_pending_participant, conference, "test_call_sid"}, nil, conferences)
  end

  test "set_call_sid_on_pending_participant when the call_sid has been set to a different call_sid returns an error", %{chairs_call_leg: chairs_call_leg} do
    conference = %Telephony.Conference{chair: chairs_call_leg, identifier: "identifier", pending_participant: %Telephony.Conference.Leg{call_sid: "test_call_sid", identifier: "participants_call_leg"}}
    conferences = %{"chair" => conference}
    assert conference.pending_participant.call_sid == "test_call_sid"
    {:reply, {:error, message}, ^conferences} = Telephony.Conference.handle_call({:set_call_sid_on_pending_participant, conference, "different_test_call_sid"}, nil, conferences)
    assert message == "call_sid already set"
  end

  test "set_call_sid_on_pending_participant when the call_sid matches the chair's call sid returns an error", %{participants_call_leg: participants_call_leg} do
    conference = %Telephony.Conference{chair: %Telephony.Conference.Leg{call_sid: "test_call_sid", identifier: "chair"}, identifier: "identifier", pending_participant: participants_call_leg}
    conferences = %{"chair" => conference}
    assert conference.chair.call_sid == "test_call_sid"
    {:reply, {:error, message}, ^conferences} = Telephony.Conference.handle_call({:set_call_sid_on_pending_participant, conference, "test_call_sid"}, nil, conferences)
    assert message == "call_sid of conference chair"
  end

  test "remove_pending_participant removes the pending participant", %{conferences: conferences, conference: conference} do
    assert conference.pending_participant != nil
    pending_participant_reference = Telephony.Conference.pending_participant_reference(conference)
    {:reply, {:ok, conference}, conferences} = Telephony.Conference.handle_call({:remove_pending_participant, pending_participant_reference}, nil, conferences)
    assert conference.pending_participant == nil
    assert Map.get(conferences, "chair") == conference
  end

  test "add_pending_participant when the pending participant is not nil returns an error", %{conferences: conferences, conference: conference} do
    assert conference.pending_participant != nil
    pending_participant_reference = Telephony.Conference.pending_participant_reference(conference)
    {:reply, {:error, message}, ^conferences} = Telephony.Conference.handle_call({:add_pending_participant, pending_participant_reference}, nil, conferences)
    assert message == "pending participant already set"
  end

  test "add_pending_participant when the pending participant is nil adds a pending participant", %{conference: conference, chairs_call_leg: chairs_call_leg} do
    pending_participant_reference = Telephony.Conference.pending_participant_reference(conference)
    conference = %Telephony.Conference{chair: chairs_call_leg, identifier: "identifier", pending_participant: nil}
    conferences = %{"chair" => conference}
    assert conference.pending_participant == nil
    {:reply, {:ok, conference}, conferences} = Telephony.Conference.handle_call({:add_pending_participant, pending_participant_reference}, nil, conferences)
    assert conference.pending_participant != nil
    assert Map.get(conferences, "chair") == conference
  end

  test "promote_pending_participant moves the pending participant into the participants list", %{chairs_call_leg: chairs_call_leg} do
    conference = %Telephony.Conference{chair: chairs_call_leg, identifier: "identifier", pending_participant: %Telephony.Conference.Leg{call_sid: "test_call_sid", identifier: "participant"}}
    conferences = %{"chair" => conference}
    assert conference.participants == %{}
    {:reply, {:ok, conference}, conferences} = Telephony.Conference.handle_call({:promote_pending_participant, conference}, nil, conferences)
    assert conference.pending_participant == nil
    assert conference.participants == %{"test_call_sid" => %Telephony.Conference.Leg{call_sid: "test_call_sid", call_status: {nil, -1}, identifier: "participant"}}
    assert Map.get(conferences, "chair") == conference
  end

  test "update_call_status_of_pending_participant when the sequence number of the updated call_status is greater than the current sequence number", %{
    conferences: conferences, conference: conference} do
    assert conference.pending_participant.call_status == {nil, -1}
    pending_participant_reference = Telephony.Conference.pending_participant_reference(conference)
    {:reply, {:ok, conference}, conferences} = Telephony.Conference.handle_call({:update_call_status_of_pending_participant, pending_participant_reference, "test_call_status", 1}, nil, conferences)
    assert conference.pending_participant.call_status == {"test_call_status", 1}
    assert Map.get(conferences, "chair") == conference
  end

  test "update_call_status_of_pending_participant when the sequence number of the updated call_status is less than the current sequence number", %{conferences: conferences, conference: conference} do
    assert conference.pending_participant.call_status == {nil, -1}
    pending_participant_reference = Telephony.Conference.pending_participant_reference(conference)
    {:reply, {:error, message}, ^conferences} = Telephony.Conference.handle_call({:update_call_status_of_pending_participant, pending_participant_reference, "test_call_status", -2}, nil, conferences)
    assert message == "call status has been superceded"
  end

  test "update_call_status_of_pending_participant when the sequence number of the updated call_status is equal to the current sequence number", %{conferences: conferences, conference: conference} do
    assert conference.pending_participant.call_status == {nil, -1}
    pending_participant_reference = Telephony.Conference.pending_participant_reference(conference)
    {:reply, {:error, message}, ^conferences} = Telephony.Conference.handle_call({:update_call_status_of_pending_participant, pending_participant_reference, "test_call_status", -1}, nil, conferences)
    assert message == "call status has been superceded"
  end

  test "remove_participant removes the participant from the participant's list", %{chairs_call_leg: chairs_call_leg, participants_call_leg: participants_call_leg} do
    conference = %Telephony.Conference{chair: chairs_call_leg, identifier: "identifier", pending_participant: nil, participants: %{"test_call_sid" => participants_call_leg}}
    conferences = %{"chair" => conference}
    assert Map.get(conference.participants, "test_call_sid") != nil
    {:reply, {:ok, conference}, conferences} = Telephony.Conference.handle_call({:remove_participant, conference, "test_call_sid"}, nil, conferences)
    assert conference.participants == %{}
    assert Map.get(conferences, "chair") == conference
  end

  test "remove when the conference is present removes the conference", %{conferences: conferences, conference: conference} do
    assert Map.get(conferences, "chair") == conference
    {:reply, {:ok, conference}, conferences} = Telephony.Conference.handle_call({:remove, conference}, nil, conferences)
    assert conferences == %{}
    assert conference != nil
  end

  test "fetch when the conference is not present returns an error", %{conference: conference} do
    reference = Telephony.Conference.reference(conference)
    conferences = %{"different_chair" => conference}
    assert Map.get(conferences, "chair") == nil
    {:reply, {:error, message}, ^conferences} = Telephony.Conference.handle_call({:fetch, reference}, nil, conferences)
    assert message == "matching conference not found"
  end

  test "fetch when the conference is present returns the conference", %{conferences: conferences, conference: conference} do
    reference = Telephony.Conference.reference(conference)
    assert Map.get(conferences, "chair") == conference
    {:reply, {:ok, ^conference}, ^conferences} = Telephony.Conference.handle_call({:fetch, reference}, nil, conferences)
  end

  test "fetch_by_pending_participant when the conference is not present returns an error", %{conference: conference} do
    reference = Telephony.Conference.pending_participant_reference(conference)
    conferences = %{"different_chair" => conference}
    assert Map.get(conferences, "chair") == nil
    {:reply, {:error, message}, ^conferences} = Telephony.Conference.handle_call({:fetch_by_pending_participant, reference}, nil, conferences)
    assert message == "matching conference not found"
  end

  test "fetch_by_pending_participant when the conference is present returns the conference", %{conferences: conferences, conference: conference} do
    reference = Telephony.Conference.pending_participant_reference(conference)
    assert Map.get(conferences, "chair") == conference
    {:reply, {:ok, ^conference}, ^conferences} = Telephony.Conference.handle_call({:fetch_by_pending_participant, reference}, nil, conferences)
  end

  test "fetch_by_pending_participant when a conference containing the specified pending participant is not found returns an error", %{conferences: conferences, conference: conference} do
    reference = Telephony.Conference.pending_participant_reference(conference)
    reference = %{reference | pending_participant_identifier: "different_participant"}
    {:reply, {:error, message}, ^conferences} = Telephony.Conference.handle_call({:fetch_by_pending_participant, reference}, nil, conferences)
    assert message == "matching conference not found"
  end
end
