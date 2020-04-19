defmodule LocalAssistantWeb.PageLive do
  use LocalAssistantWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    pages = [
      %{component: LocalAssistantWeb.ClockLive, route: Routes.clock_path(socket, :index)},
      %{component: LocalAssistantWeb.PlayerLive, route: Routes.player_path(socket, :index)}
    ]

    {:ok, assign(socket, pages: pages)}
  end

  @impl true
  def handle_params(_params, _url, socket), do: {:noreply, socket}
end
