defmodule Callbacks.Mixfile do
  use Mix.Project

  def project do
    [app: :callbacks,
     version: "0.0.1",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.2",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {Callbacks, []},
     extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.3.0-rc"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_html, "~> 2.6"},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      {:ex_twiml, github: "danielberkompas/ex_twiml"}, # For serving TwiML responses to Twilio
      {:ex_twilio, "~> 0.3.0"}, # For making requests to Twilio
      {:ex_ngrok, "~> 0.3.0", only: [:dev]}, # To allow webhook callbacks in dev
      {:ex_twilio_bootstrap, "~> 0.1.0", only: [:dev]}, # To bootstrap Twilio application in dev
      {:events, in_umbrella: true} # For publishing events to other apps
    ]
  end
end
