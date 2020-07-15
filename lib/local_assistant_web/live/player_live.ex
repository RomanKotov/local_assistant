defmodule LocalAssistantWeb.PlayerLive do
  use LocalAssistantWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> assign(action: Map.get(session, "action", "index"))
      |> assign(player: LocalAssistant.Player.get_state())
      |> browse(nil)
      |> load_playlist()
      |> assign(modal: nil)

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
  def handle_info(
        %{event: "player_state", payload: %LocalAssistant.Player.State{} = player},
        socket
      ) do
    {:noreply, socket |> assign(player: player)}
  end

  @impl true
  def handle_event("toggle_state", _, socket) do
    LocalAssistant.Player.toggle_playback()
    {:noreply, socket}
  end

  @impl true
  def handle_event("open_folder", %{"uri" => uri}, socket), do: {:noreply, browse(socket, uri)}

  @impl true
  def handle_event("play_file", %{"uri" => uri}, socket) do
    LocalAssistant.Player.play(uri)
    {:noreply, browse(socket, nil)}
  end

  @impl true
  def handle_event("seek", %{"value" => value}, socket) do
    value |> String.to_integer() |> LocalAssistant.Player.seek()
    {:noreply, socket}
  end

  @impl true
  def handle_event("set_volume", %{"value" => value}, socket) do
    value |> String.to_integer() |> LocalAssistant.Player.set_volume()
    {:noreply, socket}
  end

  @impl true
  def handle_event("previous_track", _, socket) do
    LocalAssistant.Player.previous_track()
    {:noreply, socket}
  end

  @impl true
  def handle_event("next_track", _, socket) do
    LocalAssistant.Player.next_track()
    {:noreply, socket}
  end

  @impl true
  def handle_event("shuffle", _, socket) do
    LocalAssistant.Player.shuffle()
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete_from_playlist", %{"tlid" => tlid}, socket) do
    tlid |> String.to_integer() |> LocalAssistant.Player.delete_from_playlist()
    {:noreply, load_playlist(socket)}
  end

  @impl true
  def handle_event("open_browse_modal", _, socket) do
    socket = socket |> assign(modal: "browse") |> browse(nil)
    {:noreply, socket}
  end

  @impl true
  def handle_event("open_playlist_modal", _, socket) do
    socket = socket |> assign(modal: "playlist") |> load_playlist()
    {:noreply, socket}
  end

  @impl true
  def handle_event("close_modal", _, socket), do: {:noreply, assign(socket, modal: nil)}

  defp browse(socket, uri), do: socket |> assign(tracks: LocalAssistant.Player.browse(uri))

  defp load_playlist(socket),
    do: socket |> assign(playlist: LocalAssistant.Player.get_tracklist())
end
