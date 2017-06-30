defmodule ContactCentre do
  @moduledoc """
  This application serves a single page app, which is implemented using
  Elm (http://elm-lang.org/). Communication between the client and server
  is accomplished using web sockets.
  """
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(ContactCentre.Web.Endpoint, []),
      supervisor(Registry, [:unique, ContactCentre.Conferencing.Registry]),
      # Start your own worker by calling: ContactCentre.Worker.start_link(arg1, arg2, arg3)
      # worker(ContactCentre.Worker, [arg1, arg2, arg3]),
      worker(ContactCentre.Conferencing.Identifier, []),
      worker(ContactCentre.Consumer, []),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ContactCentre.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
