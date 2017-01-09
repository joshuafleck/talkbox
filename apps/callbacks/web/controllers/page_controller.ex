defmodule Callbacks.PageController do
  use Callbacks.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
