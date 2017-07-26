defmodule ContactCentreWeb.PageControllerTest do
  use ContactCentreWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Talkbox"
  end
end
