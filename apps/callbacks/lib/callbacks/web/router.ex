defmodule Callbacks.Web.Router do
  use Callbacks.Web, :router

  pipeline :twilio do
    # TODO: assert the validity of the request from Twilio
    plug :accepts, ["html"]
  end

  scope "/callbacks", Callbacks.Web do
    scope "/twilio" do
      pipe_through :twilio
      resources "/conferences", Twilio.ConferenceController, only: [:status_changed] do
        post "/status_changed", Twilio.ConferenceController, :status_changed
        resources "/calls", Twilio.CallController, only: [:answered, :status_changed] do
          post "/answered", Twilio.CallController, :answered
          post "/status_changed", Twilio.CallController, :status_changed
        end
      end
    end
  end
end
