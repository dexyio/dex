defmodule Dex do

  use Application
  use DexyLib
  require Dex.JS

  defstruct map: %{}, js: nil

  defmacro __using__(_) do
    quote do
    end
  end # defmacro

  defmacro app, do: :dex

  defmodule Supervisor do
    use DexyLib.Supervisor, otp_app: :dex
  end

  def start(_type, _args) do
    {:ok, pid} = Supervisor.start_link
    start_riak()
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

end
