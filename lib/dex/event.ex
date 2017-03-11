defmodule Dex.Event do

  defstruct managers: []

  use GenServer
  use Dex.Common
  require Logger

  @spec start_link(Proplists.t) :: {:ok, pid} | {:error, term}

  def start_link(args \\ []) do
    state = %__MODULE__{
      managers: start_managers()
    }
    Logger.debug inspect(state)
    GenServer.start_link(__MODULE__, state, args)
  end

  def managers do
    GenServer.call __MODULE__, :managers
  end

  def add_handler manager, handler, args \\ [] do
    GenServer.call __MODULE__, {:add_handler, manager, handler, args}
  end

  def notify manager, msg do
    GenEvent.notify manager, msg
  end

  def notify_cluster manager, msg do
    nodes() |> Enum.map(& notify {manager, &1}, msg); :ok
  end

  def call manager, handler, msg do
    GenEvent.call manager, handler, msg
  end

  def send dest, msg, opts \\ []

  def send [], _msg, _opts do :ok end

  def send [dest | rest], msg, opts do
    Process.send dest, msg, opts
    __MODULE__.send rest, msg, opts
  end

  def send(dest, msg, opts) when not is_list(dest) do
    __MODULE__.send [dest], msg, opts  
  end

  def rpc_cast(nodes, module, fun, args \\ [])

  def rpc_cast(nodes, module, fun, args) when is_list(nodes) do
    nodes |> :rpc.cast(module, fun, args)
  end

  def rpc_cast(node, module, fun, args) do
    rpc_cast [node], module, fun, args
  end

  def handlers do
    GenServer.call __MODULE__, :handlers
  end

  def handlers manager do
    GenEvent.which_handlers manager
  end


  # Callbacks

  def handle_call :managers, _from, state do
    {:reply, state.managers, state}
  end

  def handle_call :handlers, _from, state do
    res = state.managers |> Enum.map(& {&1, handlers &1})
    {:reply, res, state}
  end

  def handle_call {:add_handler, manager, handler, args}, _from, state do
    res = GenEvent.add_handler manager, handler, args
    state = %{state | managers: [manager | state.managers]}
    {:reply, res, state}
  end

  def terminate(_reason, _state) do
    :ok
  end

  # private functions

  defp start_managers do
    conf()[:managers]
    |> Enum.map(fn manager ->
      {:ok, _pid} = GenEvent.start_link(name: manager)
      add_handlers manager; manager
    end)
  end
  
  defp add_handlers manager do
    (conf(manager)[:event_handlers] || [])
    |> Enum.map(fn {handler, args} ->
      GenEvent.add_handler manager, handler, args
    end)
  end

  defp nodes do
    [Node.self() | Node.list]
  end

end

