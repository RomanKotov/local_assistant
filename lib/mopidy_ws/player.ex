defmodule MopidyWS.Player do
  use GenServer

  def start_link(url, opts \\ []) do
    event_callback = Keyword.get(opts, :on_event, &IO.inspect/1)

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
    {:ok, conn} = MopidyWS.Connection.start_link(url)
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
