defmodule Events.ConferenceEnded do
  @moduledoc """
  The conference has ended - all of its participants have left. Published when
  we are notified by the telephony provider that the conference has ended.
  """
  @enforce_keys [:conference, :providers_identifier]
  defstruct [
    conference: nil,
    providers_identifier: nil
  ]

  @typedoc """
  Provides a reference to the conference.
  Fields:
    * `conference` - The conference identifier generated when a conference is requested
    * `providers_identifier` - The identifier of the conference provided by the telephony provider
  """
  @type t :: %__MODULE__{
    conference: String.t,
    providers_identifier: String.t
  }
end
