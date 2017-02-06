use Mix.Config

config :telephony,
  cli: "+440000000000",
  webhook_url: "http://test.com",
  provider: Telephony.Provider.Test,
  provider_callback_url_prefix: "/callbacks/twilio"
