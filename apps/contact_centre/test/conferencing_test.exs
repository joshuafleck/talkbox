defmodule ContactCentre.ConferencingTest do
  use ExUnit.Case, async: false

  setup do
    Events.Persistence.init
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

    event_logs_path
    |> Events.Persistence.read()
    |> Enum.filter(&external_event?(&1))
    |> Enum.map(&Events.publish(&1))

    expected_internal_events = event_logs_path
    |> Events.Persistence.read()
    |> Enum.reject(&external_event?(&1))

    :timer.sleep(100) # Give the consumer time to process
    actual_internal_events = Events.Persistence.published
    |> Enum.reject(&external_event?(&1))

    assert expected_internal_events == actual_internal_events
  end

  defp external_event?(event) do
    Enum.member?(@events_published_externally, event.__struct__)
  end
end
