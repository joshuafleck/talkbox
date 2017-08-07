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

  @events_published_without [
    Events.CallFailedToJoinConference,
    Events.CallJoinedConference,
    Events.CallLeftConference,
    Events.CallRequestFailed,
    Events.CallStatusChanged,
    Events.ChairpersonRequestsToRemoveCall,
    Events.UserRequestsCall]
  defp assert_recorded_event_logs_match_actual(context) do
    event_logs_path = "test/conferencing_test_event_logs/#{context.test}"
    unexpected_events = event_logs_path
    |> Events.Persistence.read()
    |> Enum.concat([nil]) # Indicates the last item
    |> Enum.with_index()
    |> Enum.map(&publish_external_and_wait_for_expected_event(&1))
    |> Enum.filter(&event_unexpected?(&1))

    if Enum.any?(unexpected_events) do
      first_unexpected_event = Enum.at(unexpected_events, 0)
      assert elem(first_unexpected_event, 2) == elem(first_unexpected_event, 3)
    end
  end

  defp publish_external_and_wait_for_expected_event({event, index}) do
    if event != nil && Enum.member?(@events_published_without, event.__struct__) do
      Events.publish(event)
    end
    wait_for_expected_event(event, index)
  end

  defp wait_for_expected_event(event, index, attempts \\ 0) do
    if attempts > 3 do
      {:error, index, event, published_event_at(index)}
    else
      :timer.sleep(50)
      if event == published_event_at(index) do
        {:ok, index, event}
      else
        wait_for_expected_event(event, index, attempts + 1)
      end
    end
  end

  defp published_event_at(index) do
    Enum.at(Events.Persistence.published, index)
  end

  defp event_unexpected?(result) do
    case result do
      {:ok, _, _} ->
        false
      _ ->
        true
    end
  end
end
