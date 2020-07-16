defmodule LocalAssistantWeb.PlayerLive do
  use LocalAssistantWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> assign(
        action: Map.get(session, "action", "index"),
        modal: nil,
        parent_folders: %{},
        selected_uris: MapSet.new(),
        uris_in_tracklist: MapSet.new(),
        tracks: [],
        current_uri: nil,
        player: LocalAssistant.Player.get_state()
      )
      |> browse(nil)
      |> load_playlist()

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
  def handle_event("open_folder", %{"uri" => uri}, socket) do
    {:noreply, browse(socket, uri)}
  end

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
  def handle_event("toggle_" <> action, _, socket) do
    LocalAssistant.Player.toggle(action)
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete_from_playlist", %{"tlid" => tlid}, socket) do
    [String.to_integer(tlid)] |> LocalAssistant.Player.delete_from_playlist()
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

  defp browse(socket, uri) do
    tracks = LocalAssistant.Player.browse(uri)
    parents = tracks |> Enum.map(&{&1.uri, uri}) |> Enum.into(%{})
    parent_folders = socket.assigns.parent_folders |> Map.merge(parents)

    assign(
      socket,
      tracks: tracks,
      current_uri: uri,
      parent_folders: parent_folders,
      selected_uris: MapSet.new()
    )
  end

  defp load_playlist(socket) do
    tracklist = LocalAssistant.Player.get_tracklist()
    uris_in_tracklist = tracklist |> Enum.map(& &1.track.uri) |> MapSet.new()

    assign(
      socket,
      tracklist: tracklist,
      uris_in_tracklist: uris_in_tracklist
    )
  end
end
