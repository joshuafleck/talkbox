use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :callbacks, Callbacks.Web.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :callbacks,
  cli: "+440000000000",
  webhook_url: "http://test.com",
  provider: Callbacks.Provider.Test,
  provider_callback_url_prefix: "/callbacks/twilio"
