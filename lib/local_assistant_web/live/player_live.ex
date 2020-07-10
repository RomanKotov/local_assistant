defmodule LocalAssistantWeb.PlayerLive do
  use LocalAssistantWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> assign(action: Map.get(session, "action", "index"))
      |> assign(player: LocalAssistant.Player.get_state())
      |> load_tracks(nil)

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

  @impl true
  def handle_event("open_folder", %{"uri" => uri}, socket) do
    {:noreply, load_tracks(socket, uri)}
  end

  @impl true
  def handle_event("play_file", %{"uri" => uri}, socket) do
    LocalAssistant.Player.play(uri)
    {:noreply, load_tracks(socket, nil)}
  end

  defp load_tracks(socket, uri), do: socket |> assign(tracks: LocalAssistant.Player.browse(uri))
end
