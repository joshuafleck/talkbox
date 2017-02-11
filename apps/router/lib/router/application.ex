defmodule Router.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    number_of_consumers = Application.get_env(:router, :consumers)
    children = if number_of_consumers > 0 do
      Enum.map(Range.new(1, number_of_consumers), fn(index) ->
        worker(Router.Consumer, [], [id: "Router.Consumer" <> Integer.to_string(index)])
      end)
    else
      []
    end

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Router.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
