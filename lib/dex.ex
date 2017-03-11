defmodule Dex do

  @on_load :on_load
  
  use Application
  use DexyLib

  defstruct map: %{}, js: nil

  defmacro __using__(_) do
    quote do
    end
  end # defmacro

  defmacro app, do: :dex

  defmodule Supervisor do
    use DexyLib.Supervisor, otp_app: :dex
  end

  def on_load do
    (Application.get_env(:dex, __MODULE__)[:compiler_options] || [])
      |> Elixir.Code.compiler_options
    :ok
  end

  @spec start(atom, list) :: {:ok, pid} | {:error, term}

  def start(_type, _args) do
    start_riak_core()
    res = Supervisor.start_link
    Dex.App.Pool.init()
    res
  end

  defp start_riak_core do
    case Mix.env do
      :test -> :ok
      _ ->
        :ok = :riak_core.register([{:vnode_module, Dex.Vnode}]) 
        :ok = :riak_core_node_watcher.service_up(Dex.Service, self())
    end
  end

end
