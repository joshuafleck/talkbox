defmodule Talkbox.Mixfile do
  use Mix.Project

  def project do
    [apps_path: "apps",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     aliases: aliases(),
     dialyzer: [
       plt_add_deps: :project,
       ignore_warnings: "dialyzer.ignore-warnings"]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options.
  #
  # Dependencies listed here are available only for this project
  # and cannot be accessed from applications inside the apps folder
  defp deps do
    [{:credo, "~> 0.8", only: [:dev, :test], runtime: false},
     {:dialyxir, "~> 0.5", only: :dev, runtime: false},
     {:distillery, "~> 1.4", runtime: false},
     {:ex_doc, "~> 0.15", only: :dev, runtime: false}]
  end

  defp aliases do
    [
      build: ["compile", "dialyzer", "credo"],
      package: ["compile", "phx.digest", "release --env=prod"],
      package_ui: [&brunch/1]
    ]
  end

  defp brunch(_) do
    Mix.Shell.IO.cmd("pushd apps/contact_centre/assets && node_modules/brunch/bin/brunch build --production && popd")
  end
end
