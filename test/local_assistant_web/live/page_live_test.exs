defmodule LocalAssistantWeb.PageLiveTest do
  use LocalAssistantWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Visit"
    assert render(page_live) =~ "Visit"
  end
end
