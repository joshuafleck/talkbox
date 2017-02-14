defmodule Events.UserRequestsCall do
  @moduledoc """
  A user has requested to start a call. This triggers the initiation
  of a conference, with the user acting as the chair and the callee
  acting as the pending participant.
  """
  @enforce_keys [:user, :callee]
  defstruct [
    user: nil,
    callee: nil
  ]

  @typedoc """
  Provides information on who is requesting the call and whom they are calling
  Fields:
    * `user` - The name of the user requesting the call
    * `callee` - The name (when calling a client by name) or telephone number of the person being called
  """
  @type t :: %__MODULE__{
    user: String.t,
    callee: String.t
  }
end
