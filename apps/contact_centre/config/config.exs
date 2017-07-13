# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :contact_centre, ContactCentre.Web.Endpoint,
  instrumenters: [Appsignal.Phoenix.Instrumenter], # For Appsignal APM
  url: [host: "localhost"],
  secret_key_base: "b3i2E1axl4c+47U8TS469YVNxwNMc3PLXCWJD4N98FSGu846CBle6QmiRcox3oYp",
  render_errors: [view: ContactCentre.Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: ContactCentre.PubSub,
           adapter: Phoenix.PubSub.PG2]

# For Appsignal APM
config :phoenix, :template_engines,
  eex: Appsignal.Phoenix.Template.EExEngine,
  exs: Appsignal.Phoenix.Template.ExsEngine

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :ex_twilio, account_sid: System.get_env("TWILIO_ACCOUNT_SID") || "${TWILIO_ACCOUNT_SID}",
                   auth_token:  System.get_env("TWILIO_AUTH_TOKEN") || "${TWILIO_AUTH_TOKEN}"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
