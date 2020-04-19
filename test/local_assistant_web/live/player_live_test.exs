defmodule LocalAssistantWeb.PlayerLiveTest do
  use LocalAssistantWeb.ConnCase

  import Phoenix.LiveViewTest

  defp fixture(:player) do
    %{}
  end

  defp create_player(_) do
    player = fixture(:player)
    %{player: player}
  end

  describe "Index" do
    setup [:create_player]

    test "Shows player", %{conn: conn, player: _player} do
      {:ok, _index_live, html} = live(conn, Routes.player_path(conn, :index))

      assert html =~ "MP3 Player"
    end
  end
end
