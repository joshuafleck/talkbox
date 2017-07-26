use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :telephony, TelephonyWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

config :telephony,
  cli: fn -> TwilioBootstrap.TelephoneNumber.get.phone_number end,
  webhook_url: fn -> Ngrok.public_url end,
  provider: Telephony.Provider.Twilio,
  provider_callback_url_prefix: "/telephony/twilio"

config :ex_ngrok,
  options: "--region eu",
  sleep_between_attempts: 1000

config :ex_twilio_bootstrap,
  # The friendly name of the Twilio application
  application_friendly_name: "Talkbox",
  # The friendly name of the Twilio telephone number
  telephone_number_friendly_name: "Talkbox",
  # The public URL of your server
  public_url: fn -> Ngrok.public_url end
