defmodule Dex.JS.Adapters.ErlangV8 do

  defmodule State do
    defstruct js: nil
  end

  use GenServer
  use Dex.Common

  @type reason :: atom

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  @spec call(tuple, bitstring, bitstring) :: :ok | {:error, reason}
  @spec call(tuple, bitstring, list, pos_integer) :: :ok | {:error, reason}
  
  def call {js, context}, fun, args, _timeout \\ 5000 do
    GenServer.call js, {:call, context, fun, args}
  end

  @spec eval(tuple, bitstring) :: :ok | {:error, reason}
  @spec eval(tuple, bitstring, pos_integer) :: :ok | {:error, reason}

  def eval {js, context}, script, timeout \\ 5000 do
    GenServer.call js, {:eval, context, script, timeout}
  end

  @spec take_handle() :: pid | {:error, reason}

  def take_handle do
    js = :pooler.take_member(Dex.JS)
    ctx = GenServer.call js, :create_context
    {js, ctx}
  end

  @spec return_handle(tuple) :: :ok 

  def return_handle {js, ctx} do
    GenServer.cast js, {:destroy_context, ctx}
    :pooler.return_member(Dex.JS, js)
  end

  # Callbacks

  def init(_) do
    {:ok, %State{js: new}}
  end

  def handle_call {:eval, context, str, timeout}, _from, state do
    res = case :erlang_v8.eval(state.js, context, str, timeout) do
      {:ok, val} -> {:ok, val} #{:ok, handle_evaluated val}
      {:error, reason} -> {:error, reason}
    end
    {:reply, res, state}
  end

  def handle_call {:call, context, fun, args}, _from, state do
    res = case :erlang_v8.call(state.js, context, fun, args) do
      {:ok, val} -> {:ok, handle_evaluated val}
      {:error, reason} -> {:error, reason}
    end
    {:reply, res, state}
  end

  def handle_call :create_context, _from, state do
    {:ok, context} = :erlang_v8.create_context state.js
    {:reply, context, state}
  end

  def handle_call request, from, state do
    super(request, from, state)
  end

  def handle_cast {:push, item}, state do
    {:noreply, [item|state]}
  end

  def handle_cast {:destroy_context, ctx}, state do
    :erlang_v8.destroy_context state.js, ctx
    {:noreply, state}
  end
  
  def handle_cast(request, state) do
    super(request, state)
  end

  def terminate(reason, state) do
    IO.inspect terminate: inspect reason
    destroy(state.js)
  end

  # Private functions

  defp new do
    {:ok, vm} = common_libs
      |> Enum.map(& {:file, &1})
      |> :erlang_v8.start_vm
    vm
  end

  defp priv_dir do
    :code.priv_dir(Dex.app) |> to_string
  end

  defp common_libs do
    js_path = priv_dir <> "/js/"
    (conf(Dex.JS)[:libs] || [])
      |> Enum.map(&String.to_charlist(js_path <> &1))
  end

  defp handle_evaluated({:struct, list}) do
    Enum.into handle_evaluated(list), %{}, fn {key, val} ->
      {key, handle_evaluated val}
    end
  end

  defp handle_evaluated(list) when is_list(list) do
    Enum.into list, [], fn val ->
      handle_evaluated(val)
    end
  end

  defp handle_evaluated(val) do val end

  defp destroy(js) do
    :erlang_v8.stop_vm(js)
  end

end

