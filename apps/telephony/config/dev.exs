use Mix.Config

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

config :telephony,
  cli: fn -> TwilioBootstrap.TelephoneNumber.get.phone_number end,
  webhook_url: fn -> Ngrok.public_url end,
  provider: Telephony.Twilio,
  provider_callback_url_prefix: "/callbacks/twilio"
