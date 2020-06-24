defmodule MopidyWS.Connection do
  use WebSockex

  def start_link(url, opts \\ []) do
    WebSockex.start_link(url, __MODULE__, %{pid: self()}, opts)
  end

  def handle_frame({:text, msg}, state = %{pid: pid}) do
    send(pid, {:message, Jason.decode!(msg)})
    {:ok, state}
  end

  def send_message(pid, data) do
    frame = {:text, Jason.encode!(data)}
    WebSockex.send_frame(pid, frame)
  end

  def handle_disconnect(_conn, state=%{pid: pid}) do
    Process.exit(pid, :disconnected)
    {:ok, state}
  end
end
