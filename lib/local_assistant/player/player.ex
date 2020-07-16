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

  def toggle(feature), do: GenServer.call(__MODULE__, {:toggle, feature})

  def play_single(uri) do
    clear_tracklist()
    [%{tlid: tlid}] = add_to_tracklist([uri])
    command(API.Playback, :play, [nil, tlid])
  end

  def browse(uri),
    do: command(API.Library, :browse, [uri])

  def add_to_tracklist(uris) when is_list(uris) do
    command(API.Tracklist, :add, [nil, nil, uris])
  end

  def get_tracklist(), do: command(API.Tracklist, :get_tl_tracks, [])

  def clear_tracklist(), do: command(API.Tracklist, :clear, [])

  def delete_from_tracklist(tlids) when is_list(tlids),
    do: command(API.Tracklist, :remove, [%{"tlid" => tlids}])

  def seek(value), do: command(API.Playback, :seek, [value])

  def set_volume(value), do: command(API.Mixer, :set_volume, [value])

  def previous_track(), do: command(API.Playback, :previous, [])

  def next_track(), do: command(API.Playback, :next, [])

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
        "playing" -> API.Playback.pause(pid)
        _ -> API.Playback.play(pid)
      end

    {:reply, response, state}
  end

  @impl true
  def handle_call({:toggle, feature}, _, state = %{pid: pid, player: player}) do
    {key, function} =
      case feature do
        "single" -> {:single, &API.Tracklist.set_single/2}
        "repeat" -> {:repeat, &API.Tracklist.set_repeat/2}
        "consume" -> {:consume, &API.Tracklist.set_consume/2}
        "random" -> {:random, &API.Tracklist.set_random/2}
      end

    value = player |> Map.fetch!(key)
    {:ok, response} = function.(pid, !value)

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
    new_player =
      %{
        state: &API.Playback.get_state/1,
        position: &API.Playback.get_time_position/1,
        volume: &API.Mixer.get_volume/1,
        stream_title: &API.Playback.get_stream_title/1,
        repeat: &API.Tracklist.get_repeat/1,
        single: &API.Tracklist.get_single/1,
        random: &API.Tracklist.get_random/1,
        consume: &API.Tracklist.get_consume/1
      }
      |> Enum.reduce(
        player,
        fn {key, getter}, acc ->
          {:ok, value} = getter.(pid)
          acc |> Map.replace!(key, value)
        end
      )

    new_player =
      with {:ok, tl_data} = API.Playback.get_current_tl_track(pid) do
        {tlid, track} =
          case tl_data do
            nil -> {nil, nil}
            %MopidyWS.Models.TlTrack{tlid: tlid, track: track} -> {tlid, track}
          end

        %{new_player | tlid: tlid, track: track}
      end

    refresh_state()

    {:noreply, update_player(state, new_player)}
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
