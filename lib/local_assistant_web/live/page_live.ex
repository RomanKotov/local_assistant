defmodule LocalAssistantWeb.PageLive do
  use LocalAssistantWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(
        :pages,
        [
          %{component: LocalAssistantWeb.PlayerLive, route: Routes.player_path(socket, :index)}
        ]
      )

    {:ok, socket}
  end
end
