defmodule Telephony.Conference.Reference do
  @moduledoc """
  A reference to a conference. A conference reference consists of the
  chairperson's name and the conference identifier as generated by the
  conference module. This can be used to pass a reference to a conference
  between applications. Note that the conference identifier actually already
  contains the chairperson's name, but it is also stored in a separate
  field for convenience.

  """
  @enforce_keys [:identifier, :chair]
  defstruct [
    identifier: nil,
    chair: nil
  ]

  @typedoc """
  A reference to a conference.
  Fields:
    * `identifier` - Our internally-generated conference identifier
    * `chair` - The name of the conference chairperson
  """
  @type t :: %__MODULE__{
    identifier: String.t,
    chair: String.t
  }
end