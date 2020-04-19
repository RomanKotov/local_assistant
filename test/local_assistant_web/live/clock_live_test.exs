defmodule LocalAssistantWeb.ClockLiveTest do
  use LocalAssistantWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "Index" do
    test "lists all player", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, Routes.clock_path(conn, :index))

      assert html =~ "Clock"
    end
  end
end
