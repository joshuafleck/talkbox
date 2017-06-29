defmodule ContactCentre.Conferencing.Call do
  @moduledoc """
  The representation of a conference participant or chairperson's call leg.
  """
  @enforce_keys [:identifier, :destination]
  defstruct [
    identifier: nil,
    destination: nil,
    providers_identifier: nil,
    status: {nil, -1}
  ]

  @typedoc """
  The representation of a conference participant or chairperson's call leg.
  Fields:
    * `identifier` - Internal identifier of the call
    * `destination` - The chairperson's name or the participant's name (when calling a client by name) or telephone number
    * `providers_identifier` - The identifier of the call provided by the telephony provider upon initiating the call, which we use for manipulating the call state
    * `status` - The name of the most recent call status and the sequence in which the call status arrived
  """
  @type t :: %__MODULE__{
    identifier: ContactCentre.Conferencing.Identifier.t,
    destination: String.t,
    providers_identifier: String.t | nil,
    status: {String.t | nil, integer}
  }

  @doc """
  Returns true if the provider's identifier
  has been set on the call, which indicates
  that the call has been requested to the
  telephony provider.
  """
  @spec requested?(t) :: boolean
  def requested?(call) do
    call.providers_identifier != nil
  end

  @doc """
  Returns true if the call's status
  is in progress, which indicates the
  call is part of a conference.
  """
  @spec in_conference?(t) :: boolean
  def in_conference?(call) do
    "in-progress" == call.status
  end

  @doc"""
  Creates a new Call struct
  """
  @spec new(String.t) :: t
  def new(destination) do
    %__MODULE__{identifier: ContactCentre.Conferencing.Identifier.get_next(), destination: destination}
  end
end
