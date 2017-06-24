defmodule Callbacks do
  @moduledoc """
  Responsible for responding to callback requests from telephony providers.
  A typical response will either return a TwiML instruction with `Callbacks.Twiml`
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
      supervisor(Callbacks.Web.Endpoint, []),
      # Start your own worker by calling: Callbacks.Worker.start_link(arg1, arg2, arg3)
      # worker(Callbacks.Worker, [arg1, arg2, arg3]),
      worker(Callbacks.Consumer, []),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Callbacks.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
