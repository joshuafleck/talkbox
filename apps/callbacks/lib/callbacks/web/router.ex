defmodule Callbacks.Web.Router do
  use Callbacks.Web, :router

  pipeline :twilio do
    # TODO: assert the validity of the request from Twilio
    plug :accepts, ["html"]
  end

  scope "/callbacks", Callbacks.Web do
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
