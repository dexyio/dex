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

  @spec start(atom, list) :: {:ok, pid} | {:error, term}

  def start(_type, _args) do
    start_riak_core()
    Supervisor.start_link
  end

  defp start_riak_core do
    case Mix.env do
      :test -> :ok
      _ ->
        :ok = :riak_core.register([{:vnode_module, Dex.Service.Vnode}]) 
        :ok = :riak_core_node_watcher.service_up(Dex.Service, self())
    end
  end

end
