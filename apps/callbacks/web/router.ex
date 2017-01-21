defmodule Callbacks.Router do
  use Callbacks.Web, :router

  pipeline :twilio do
    plug :accepts, ["html"]
  end

  # TODO: need to handle 404s, 500s, etc as there is no error view
  scope "/callbacks", Callbacks do
    scope "/twilio" do
      pipe_through :twilio

      post "/chair_answered", TwilioController, :chair_answered
      post "/chair_call_status_changed", TwilioController, :chair_call_status_changed
      post "/pending_participant_answered", TwilioController, :pending_participant_answered
      post "/participant_call_status_changed", TwilioController, :participant_call_status_changed
      post "/conference_status_changed", TwilioController, :conference_status_changed
    end
  end
end
