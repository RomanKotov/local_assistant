defmodule LocalAssistant.Player do
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

  @impl true
  def init(state) do
    {:ok, pid} = MopidyWS.API.connect()
    refresh_state()
    {:ok, %{state | pid: pid}}
  end

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

  defp refresh_state() do
    Process.send_after(self(), :refresh_state, 1000)
  end
end
