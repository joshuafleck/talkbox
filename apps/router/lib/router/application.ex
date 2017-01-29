defmodule Router.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      # Starts a worker by calling: Router.Worker.start_link(arg1, arg2, arg3)
      # worker(Router.Worker, [arg1, arg2, arg3]),
      # TODO: how many consumers should we run?
      # TODO: make sure consumer reconnects when the process crashes
      worker(Router.Consumer, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Router.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
