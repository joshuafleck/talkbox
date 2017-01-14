defmodule Callbacks.Router do
  use Callbacks.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :twilio do
    plug :accepts, ["html"]
  end

  # scope "/", Callbacks do
  #   pipe_through :browser # Use the default browser stack
  #   get "/", PageController, :index
  # end

  # Other scopes may use custom stacks.
  # scope "/api", Callbacks do
  #   pipe_through :api
  # end

  # TODO: need to handle 404s, 500s, etc as there is no error view
  scope "/callbacks", Callbacks do
    scope "/twilio" do
      pipe_through :twilio

      post "/chair_answered", TwilioController, :chair_answered
    end
  end
end
