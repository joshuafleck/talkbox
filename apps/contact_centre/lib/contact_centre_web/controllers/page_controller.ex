defmodule ContactCentreWeb.PageController do
  use ContactCentreWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
