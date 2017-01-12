defmodule Dex do

  use Application
  use DexyLib
  use Dex.Sup
  require Dex.JS

  defstruct map: %{}, js: nil

  defmacro __using__(_) do
    quote do
    end
  end # defmacro

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

end
