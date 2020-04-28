defmodule LocalAssistantWeb.ClockLive do
  use LocalAssistantWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> assign(action: Map.get(session, "action", "index"))
      |> set_time()

    {:ok, socket}
  end

  @impl true
  def render(%{action: action} = assigns) do
    Phoenix.View.render(LocalAssistantWeb.ClockLiveView, "#{action}.html", assigns)
  end

  @spec set_time(Socket.t) :: Socket.t
  defp set_time(socket) do
    schedule_tick()
    time = :calendar.local_time() |> NaiveDateTime.from_erl!()

    assign(socket, time: time)
  end

  @impl true
  def handle_info(:tick, socket) do
    {:noreply, set_time(socket)}
  end

  defp schedule_tick(), do: Process.send_after(self(), :tick, 1000)
end
