defmodule LocalAssistant.Player do
  @topic "player_updates"
  @url "http://localhost:6680/mopidy/ws"
  alias MopidyWS.API
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      %{
        pid: nil,
        player: %LocalAssistant.Player.State{}
      },
      opts
    )
  end

  def connect(url \\ @url) do
    :ok = disconnect()
    GenServer.call(__MODULE__, {:connect, url})
  end

  def disconnect(), do: GenServer.call(__MODULE__, :disconnect)

  def process_event(event), do: GenServer.cast(__MODULE__, {:event, event})

  def subscribe(), do: LocalAssistantWeb.Endpoint.subscribe(@topic)

  def get_state(), do: GenServer.call(__MODULE__, :get_state)

  def toggle_playback(), do: GenServer.call(__MODULE__, :toggle_playback)

  def browse(uri),
    do: command(MopidyWS.API.Library, :browse, [uri])

  def play(uri) do
    [%MopidyWS.Models.TlTrack{tlid: tlid}] =
      command(MopidyWS.API.Tracklist, :add, [nil, nil, [uri]])

    command(MopidyWS.API.Playback, :play, [nil, tlid])
  end

  def get_tracklist(), do: command(MopidyWS.API.Tracklist, :get_tl_tracks, [])

  def delete_from_playlist(tlid) do
    command(MopidyWS.API.Tracklist, :remove, [%{"tlid" => [tlid]}])
  end

  def seek(value), do: command(MopidyWS.API.Playback, :seek, [value])

  def set_volume(value), do: command(MopidyWS.API.Mixer, :set_volume, [value])

  def previous_track(), do: command(MopidyWS.API.Playback, :previous, [])

  def next_track(), do: command(MopidyWS.API.Playback, :next, [])

  defp command(module, function, args),
    do: GenServer.call(__MODULE__, {:command, {module, function, args}})

  @impl true
  def init(state) do
    Process.flag(:trap_exit, true)

    refresh_state()

    {:ok, state, {:continue, :connect}}
  end

  @impl true
  def handle_continue(:connect, state) do
    {_response, new_state} = state |> connect_to_player(@url)
    {:noreply, new_state}
  end

  @impl true
  def handle_call(:disconnect, _, state = %{pid: nil}), do: {:reply, :ok, state}

  @impl true
  def handle_call(:disconnect, _, state = %{pid: pid}) do
    Process.exit(pid, :disconnected)
    {:reply, :ok, %{state | pid: nil}}
  end

  @impl true
  def handle_call({:connect, url}, _, state = %{pid: nil}) do
    {response, new_state} = state |> connect_to_player(url)
    {:reply, response, new_state}
  end

  @impl true
  def handle_call(:get_state, _, state = %{player: player}), do: {:reply, player, state}

  @impl true
  def handle_call(:toggle_playback, _, state = %{pid: pid, player: player}) do
    {:ok, response} =
      case player.state do
        "playing" -> MopidyWS.API.Playback.pause(pid)
        _ -> MopidyWS.API.Playback.play(pid)
      end

    {:reply, response, state}
  end

  @impl true
  def handle_call({:command, {module, function, args}}, _, state = %{pid: pid})
      when is_list(args) do
    {:ok, response} = apply(module, function, [pid | args])

    {:reply, response, state}
  end

  @impl true
  def handle_cast({:event, event}, state) do
    result = event |> handle_event()

    new_player =
      struct(
        LocalAssistant.Player.State,
        state.player |> Map.merge(result) |> Map.from_struct()
      )

    {:noreply, update_player(state, new_player)}
  end

  @impl true
  def handle_info(:refresh_state, state = %{pid: nil}), do: {:noreply, state}

  @impl true
  def handle_info(:refresh_state, state = %{pid: pid, player: player}) do
    {:ok, player_state} = pid |> API.Playback.get_state()
    player = %{player | state: player_state}

    {:ok, track} = pid |> API.Playback.get_current_track()
    player = %{player | track: track}

    {:ok, position} = pid |> API.Playback.get_time_position()
    player = %{player | position: position}

    {:ok, volume} = pid |> API.Mixer.get_volume()
    player = %{player | volume: volume}

    refresh_state()

    {:noreply, update_player(state, player)}
  end

  def handle_info({:EXIT, _pid, :disconnected}, state), do: {:noreply, %{state | pid: nil}}

  defp refresh_state() do
    Process.send_after(self(), :refresh_state, 1000)
  end

  defp connect_to_player(state, url) do
    case MopidyWS.Player.start_link(url, &process_event/1) do
      {:ok, pid} ->
        {:ok, %{state | pid: pid}}

      result ->
        {result, state}
    end
  end

  def handle_event(%{"event" => "volume_changed", "volume" => volume}), do: %{volume: volume}

  def handle_event(%{"event" => "playback_state_changed", "new_state" => state}),
    do: %{state: state}

  def handle_event(%{
        "tl_track" => %MopidyWS.Models.TlTrack{track: track},
        "time_position" => position
      }),
      do: %{track: track, position: position}

  def handle_event(%{"event" => "seeked", "time_position" => position}),
    do: %{position: position}

  def handle_event(_), do: %{}

  def update_player(state, player = %{track: track}) do
    player = if is_nil(track), do: %{player | track: %MopidyWS.Models.Track{}}, else: player

    LocalAssistantWeb.Endpoint.broadcast!(@topic, "player_state", player)
    %{state | player: player}
  end
end
