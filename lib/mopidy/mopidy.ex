defmodule Mopidy do
  @moduledoc """
  Mopidy represents connection to Mopidy player
  """

  def api_json() do
    with path <- Path.join(Path.dirname(__ENV__.file), "mopidy_api.json"),
         {:ok, body} <- File.read(path),
         {:ok, json} <- Jason.decode(body) do
      json
    end
  end

  def module_information() do
    key_fn = fn {key, _value} ->
      key
      |> String.replace("core.", "")
      |> String.split(".")
      |> Enum.slice(0..-2)
      |> Enum.map(&String.capitalize/1)
      |> Enum.join(".")
    end

    value_fn = fn {key, value} ->
      %{
        method: key |> String.split(".") |> List.last(),
        api_method: key,
        description: value["description"],
        params: value["params"]
      }
    end

    api_json() |> Enum.group_by(key_fn, value_fn)
  end

  defmacro generate_api() do
    generate_function_ast = fn meta ->
      IO.inspect(meta)
      quote do
        @doc unquote(meta.description)
        def unquote(String.to_atom(meta.method))() do
          Mopidy.Player.command(unquote(__CALLER__.module), unquote(meta.api_method))
        end
      end
    end

    generate_module_ast = fn {name, function_list} ->
      function_ast = function_list |> Enum.map(generate_function_ast)

      if name != "" do
        quote do
          defmodule unquote(String.to_atom("#{__CALLER__.module}.#{name}")) do
            unquote(function_ast)
          end
        end
      else
        quote do
          unquote(function_ast)
        end
      end
    end

    ast = module_information() |> Enum.map(generate_module_ast)

    quote do
      @url "http://localhost:6680/mopidy/ws"

      @doc "Connect to an instance"
      def connect(url \\ @url) do
        {:ok, _pid} = Mopidy.Player.start_link(url, name: unquote(__CALLER__.module))
        :ok
      end

      unquote ast
    end
  end
end
