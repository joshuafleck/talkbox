defprotocol Events.Handler do
  @doc """
  Given an event will apply behaviour specific to that event
  """
  def handle(event)
end

defimpl Events.Handler, for: Any do
  def handle(_), do: {:ok, nil}
end
