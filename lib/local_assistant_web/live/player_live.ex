defmodule LocalAssistantWeb.PlayerLive do
  use LocalAssistantWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> assign(action: Map.get(session, "action", "index"))
      |> assign(player: LocalAssistant.Player.get_state())

    if connected?(socket) do
      LocalAssistant.Player.subscribe()
    end

    {:ok, socket}
  end

  @impl true
  def render(%{action: action} = assigns) do
    Phoenix.View.render(LocalAssistantWeb.PlayerLiveView, "#{action}.html", assigns)
  end

  @impl true
  def handle_info(%{event: "player_state", payload: %LocalAssistant.Player.State{} = player}, socket) do
    {:noreply, socket |> assign(player: player)}
  end

  @impl true
  def handle_event("toggle_state", _, socket) do
    LocalAssistant.Player.toggle_state()
    {:noreply, socket}
  end
end
