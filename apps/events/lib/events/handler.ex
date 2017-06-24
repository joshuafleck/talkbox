defprotocol Events.Handler do
  @doc """
  Given an event, will apply behaviour specific to that event
  Any event that is fired should have a corresponding
  handler implemented.
  """
  @spec handle(Events.t) :: any
  def handle(event)
end
