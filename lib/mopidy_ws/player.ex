defmodule MopidyWS.Player do
  use GenServer

  def start_link(url, event_callback \\ &IO.inspect/1, opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      %{
        url: url,
        conn: nil,
        requests: %{},
        on_event: event_callback,
        id: 1
      },
      opts
    )
  end

  def command(pid, method, params \\ []) do
    GenServer.call(pid, {:command, method, params})
  end

  @impl true
  def init(state = %{url: url}) do
    case MopidyWS.Connection.start_link(url, handle_initial_conn_failure: true) do
      {:ok, conn} -> {:ok, %{state | conn: conn}}
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl true
  def handle_call({:command, method, params}, from, state = %{id: id, requests: requests}) do
    message = %{
      "jsonrpc" => "2.0",
      "id" => id,
      "method" => method,
      "params" => params
    }

    MopidyWS.Connection.send_message(state.conn, message)

    {:noreply, %{state | id: id + 1, requests: Map.put(requests, id, from)}}
  end

  @impl true
  def handle_info({:message, %{"id" => id, "result" => result}}, state),
    do: reply(state, id, {:ok, MopidyWS.Models.deserialize(result)})

  @impl true
  def handle_info({:message, %{"id" => id, "error" => error}}, state),
    do: reply(state, id, {:error, error})

  def handle_info({:message, data = %{"event" => _event}}, state = %{on_event: event_callback}) do
    data |> MopidyWS.Models.deserialize() |> event_callback.()
    {:noreply, state}
  end

  defp reply(state = %{requests: requests}, id, data) do
    GenServer.reply(Map.get(requests, id), data)
    {:noreply, %{state | requests: Map.delete(requests, id)}}
  end
end
