defmodule Events.ConferenceDeleted do
  @moduledoc """
  A conference has been deleted - this is an internal event not
  triggered by any telephony provider but used to indicate that
  the conference has been deleted from the system.
  """
  @enforce_keys [:conference]
  defstruct [
    conference: nil
  ]
  @typedoc """
  Contains the conference state at the point of deletion.
  """
  @type t :: %__MODULE__{
    conference: struct
  }
end
