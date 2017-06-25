defmodule ContactCentre.Web.PageController do
  use ContactCentre.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
