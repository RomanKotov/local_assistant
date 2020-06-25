defmodule LocalAssistant.Player do
  @url "http://localhost:6680/mopidy/ws"
  alias MopidyWS.API
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      %{
        pid: nil,
        player: %{status: "stopped", track: nil}
      },
      opts
    )
  end

  def connect(url \\ @url) do
    :ok = disconnect()
    GenServer.call(__MODULE__, {:connect, url})
  end

  def disconnect() do
    GenServer.call(__MODULE__, :disconnect)
  end

  @impl true
  def init(state) do
    Process.flag(:trap_exit, true)
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
    MopidyWS.API.disconnect(pid)
    {:reply, :ok, %{state | pid: nil}}
  end

  @impl true
  def handle_call({:connect, url}, _, state = %{pid: nil}) do
    {response, new_state} = state |> connect_to_player(url)
    {:reply, response, new_state}
  end

  @impl true
  def handle_info(:refresh_state, state = %{pid: nil}), do: {:noreply, state}

  @impl true
  def handle_info(:refresh_state, state = %{pid: pid, player: player}) do
    {:ok, status} = pid |> API.Playback.get_state()
    player = %{player | status: status}

    {:ok, track} = pid |> API.Playback.get_current_track()
    player = %{player | track: track}

    if status == "playing" do
      refresh_state()
    end

    {:noreply, %{state | player: player}}
  end

  def handle_info({:EXIT, _pid, :disconnected}, state), do: {:noreply, %{state | pid: nil}}

  defp refresh_state() do
    Process.send_after(self(), :refresh_state, 1000)
  end

  defp connect_to_player(state, url) do
    case MopidyWS.API.connect(url) do
      {:ok, pid} ->
        refresh_state()
        {:ok, %{state | pid: pid}}

      result ->
        {result, state}
    end
  end
end
