defmodule TelephonyWeb do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use TelephonyWeb, :controller
      use TelephonyWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: TelephonyWeb

      import TelephonyWeb.Router.Helpers
      import TelephonyWeb.Gettext
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "lib/telephony_web/templates",
                        namespace: TelephonyWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import TelephonyWeb.Router.Helpers
      import TelephonyWeb.ErrorHelpers
      import TelephonyWeb.Gettext
    end
  end

  def router do
    quote do
      use Phoenix.Router
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
