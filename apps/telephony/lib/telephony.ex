defmodule Telephony do
  @moduledoc """
  Responsible for responding to callback requests from and sending
  instructions via API to telephony providers.
  A typical response will either return a TwiML instruction with `Telephony.Twiml`
  or will fire an event using the `Events` module.
  """
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(Telephony.Web.Endpoint, []),
      # Start your own worker by calling: Telephony.Worker.start_link(arg1, arg2, arg3)
      # worker(Telephony.Worker, [arg1, arg2, arg3]),
      worker(Telephony.Consumer, []),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Telephony.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
