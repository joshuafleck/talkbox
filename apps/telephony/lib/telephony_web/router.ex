defmodule TelephonyWeb.Router do
  use TelephonyWeb, :router

  pipeline :twilio do
    plug :accepts, ["html"]
  end

  scope "/telephony", TelephonyWeb do
    scope "/twilio", Twilio do
      pipe_through :twilio
      resources "/conferences", ConferenceController, only: [:status_changed] do
        post "/status_changed", ConferenceController, :status_changed, as: :status_changed
        resources "/calls", CallController, only: [:answered, :status_changed] do
          post "/answered", CallController, :answered, as: :answered
          post "/status_changed", CallController, :status_changed, as: :status_changed
        end
      end
    end
  end
end
