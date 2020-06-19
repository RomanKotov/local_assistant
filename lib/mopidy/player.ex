defmodule Mopidy.Player do
  use GenServer

  def start_link(url, opts \\ []) do
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
  def handle_info({:message, %{"id" => id, "result" => result}}, state),
    do: reply(state, id, {:ok, parse_result(result)})

  @impl true
  def handle_info({:message, %{"id" => id, "error" => error}}, state),
    do: reply(state, id, {:error, error})

  def handle_info({:message, data = %{"event" => _event}}, state) do
    IO.inspect(data)
    {:noreply, state}
  end

  def parse_result(result) when is_list(result) do
    result |> Enum.map(&parse_result/1)
  end

  def parse_result(result = %{"__model__" => model}), do: parse_model(model, result)

  def parse_result(result), do: result

  def parse_model(model_name, result) do
    model = Map.fetch!(available_models(), model_name) |> struct
    keys = model |> Map.keys() |> Enum.filter(&(&1 != :__struct__))

    data =
      for key <- keys, into: %{} do
        value = result["#{key}"]
        {key, parse_result(value)}
      end

    struct(model, data)
  end

  def available_models() do
    base_module_str = Mopidy.Models |> Atom.to_string() |> (&"#{&1}.").()

    with {:ok, list} <- :application.get_key(:local_assistant, :modules) do
      for module <- list,
          module_name = module |> Atom.to_string(),
          module_name |> String.starts_with?(base_module_str),
          key = module_name |> String.replace(base_module_str, ""),
          into: %{} do
        {key, module}
      end
    end
  end

  defp reply(state = %{requests: requests}, id, data) do
    GenServer.reply(Map.get(requests, id), data)
    {:noreply, %{state | requests: Map.delete(requests, id)}}
  end
end
