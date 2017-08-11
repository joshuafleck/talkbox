defmodule ContactCentre.ConferencingTest do
  use ExUnit.Case, async: false

  setup do
    Events.Persistence.init
    ContactCentre.Conferencing.Identifier.reset
    Logger.metadata(application: :events)
    Logger.configure(level: :info)
    on_exit fn ->
      Logger.metadata(application: nil)
      Logger.configure(level: :warn)
    end
  end

  test "a conference between two people", context do
    assert_recorded_event_logs_match_actual(context)
  end

  test "a conference between three people", context do
    assert_recorded_event_logs_match_actual(context)
  end

  test "a conference where the callee hangs up first", context do
    assert_recorded_event_logs_match_actual(context)
  end

  test "a conference where the callee's number is invalid", context do
    assert_recorded_event_logs_match_actual(context)
  end

  test "a conference where the callee cannot be reached", context do
    assert_recorded_event_logs_match_actual(context)
  end

  test "a conference where the chairperson cannot be reached", context do
    assert_recorded_event_logs_match_actual(context)
  end

  test "a conference where the call is ended before it could be connected", context do
    assert_recorded_event_logs_match_actual(context)
  end

  @events_published_externally [
    Events.CallFailedToJoinConference,
    Events.CallJoinedConference,
    Events.CallLeftConference,
    Events.CallRequestFailed,
    Events.CallStatusChanged,
    Events.ChairpersonRequestsToRemoveCall,
    Events.ConferenceEnded,
    Events.UserRequestsCall]
  defp assert_recorded_event_logs_match_actual(context) do
    event_logs_path = "test/conferencing_test_event_logs/#{context.test}"
    assert File.exists?(event_logs_path), "Missing test event logs file expected at: #{event_logs_path}"
    expected_events = Events.Persistence.read(event_logs_path)
    publish_external_events(expected_events)
    :timer.sleep(100) # Give the consumer time to process
    assert expected_internal_events(expected_events) == actual_internal_events()
  end

  defp external_event?(event) do
    Enum.member?(@events_published_externally, event.__struct__)
  end

  defp publish_external_events(expected_events) do
    expected_events
    |> Enum.filter(&external_event?(&1))
    |> Enum.each(&Events.publish(&1))
  end

  defp expected_internal_events(expected_events) do
    expected_events
    |> Enum.reject(&external_event?(&1))
  end

  defp actual_internal_events do
    Events.Persistence.published
    |> Enum.reject(&external_event?(&1))
  end
end
