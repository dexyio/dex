defmodule Dex do

  use Application
  use DexyLib
  use Dex.Sup
  require Dex.JS

  defstruct map: %{}, js: nil

  @type t :: %__MODULE__{
    map: map,
  }

  defmacro __using__(_) do
    quote do
    end
  end # defmacro

  defmacro deferror name, code \\ nil do
    quote do
      defmodule unquote(name) do
        defexception message: to_string(unquote name)
                              |> String.trim_leading("Elixir.Dex.Error."),
                     code: unquote(code),
                     reason: nil,
                     state: nil
      end
    end
  end

  defmacro app, do: :dex

  def start(_type, _args) do
    {:ok, pid} = start_sup
    start_riak
    {:ok, pid}
  end

  defp start_riak do
    case Mix.env do
      :test -> :ok
      _ ->
        :ok = :riak_core.register([{:vnode_module, Dex.Service.Vnode}]) 
        :ok = :riak_core_node_watcher.service_up(Dex.Service, self())
    end
  end

  def _start_sup do
    import Elixir.Supervisor.Spec, warn: false
    children = [
      supervisor(:pooler_sup, [])
    ]
    opts = [strategy: :one_for_one, name: Dex.Supervisor]
    Elixir.Supervisor.start_link(children, opts)
  end

  def new do
    %Dex{
      map: Mappy.new,
      js: nil
    }
  end

  def set(dex, key, val) do
    put_in(
      dex.map,
      Mappy.set(dex.map, key, val)
    )
  end

  def val(dex, key, default \\ nil) do
    case Mappy.get(dex.map, key) do
      :error -> default
      val -> val
    end
  end

  def merge(dex, map) do
    put_in(
      dex.map,
      Mappy.merge(dex.map, map)
    )
  end

  def count(enum) do
    Enum.count enum
  end

  def count(dex, key) do
    Mappy.count(dex.map, key)
  end

  def keys(dex) do
    Mappy.keys(dex.map)
  end

  def keys(dex, key) do
    Mappy.keys(dex.map, key)
  end

end
