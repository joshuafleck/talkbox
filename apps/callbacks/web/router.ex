defmodule Callbacks.Router do
  use Callbacks.Web, :router

  pipeline :twilio do
    plug :accepts, ["html"]
  end

  # TODO: need to handle 404s, 500s, etc as there is no error view
  scope "/callbacks", Callbacks do
    scope "/twilio" do
      pipe_through :twilio
      scope "/call" do
        post "/chair_answered", Twilio.CallController, :chair_answered
        post "/chair_status_changed", Twilio.CallController, :chair_status_changed
        post "/pending_participant_answered", Twilio.CallController, :pending_participant_answered
        post "/participant_status_changed", Twilio.CallController, :participant_status_changed
      end
      scope "/conference" do
        post "/status_changed", Twilio.ConferenceController, :status_changed
      end
    end
  end
end
