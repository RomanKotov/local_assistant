defmodule Mopidy.Player do
  use GenServer
  @url "http://localhost:6680/mopidy/ws"

  def start_link(url \\ @url, opts \\ []) do
    GenServer.start_link(__MODULE__, %{url: url, conn: nil, requests: %{}, id: 1}, opts)
  end

  def command(pid, method, params \\ []) do
    GenServer.call(pid, {:command, method, params})
  end

  @impl true
  def init(state = %{url: url}) do
    {:ok, conn} = Mopidy.Connection.start_link(url)
    {:ok, %{state | conn: conn}}
  end

  @impl true
  def handle_call({:command, method, params}, from, state = %{id: id, requests: requests}) do
    message = %{
      "jsonrpc" => "2.0",
      "id" => id,
      "method" => method,
      "params" => params
    }

    Mopidy.Connection.send_message(state.conn, message)

    {:noreply, %{state | id: id + 1, requests: Map.put(requests, id, from)}}
  end

  @impl true
  def handle_info({:message, data = %{"id" => id}}, state = %{requests: requests}) do
    GenServer.reply(Map.get(requests, id), data["result"])
    {:noreply, %{state | requests: Map.delete(requests, id)}}
  end
end
