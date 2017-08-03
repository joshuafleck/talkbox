defmodule Events.ConferenceCreated do
  @moduledoc """
  A conference has been created - this is an internal event not
  triggered by any telephony provider but used to indicate that
  a new conference exists in the system.
  """
  @enforce_keys [:user, :conference]
  defstruct [
    user: nil,
    conference: nil
  ]
   @typedoc """
   Contains the user that requested the conference and the
   state of the conference itself.
   """
   @type t :: %__MODULE__{
     user: String.t,
     conference: struct
   }
end
