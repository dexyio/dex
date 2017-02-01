defmodule Dex.JS.Adapters.ErlangJS do

  defmodule State do
    defstruct js: nil
  end

  use GenServer
  use Dex.Common

  @type reason :: atom

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  @spec define(pid, bitstring) :: :ok | {:error, reason}

  def define(handle, script) do
    GenServer.call handle, {:define, script}
  end

  @spec call(pid, bitstring, bitstring) :: :ok | {:error, reason}
  @spec call(pid, bitstring, list, pos_integer) :: :ok | {:error, reason}

  def call handle, fun, args, _timeout \\ 5000 do
    GenServer.call handle, {:call, fun, args}
  end

  @spec eval(pid, bitstring) :: :ok | {:error, reason}
  @spec eval(pid, bitstring, pos_integer) :: :ok | {:error, reason}

  def eval handle, script, timeout \\ 5000 do
    GenServer.call handle, {:eval, script, timeout}
  end

  @spec take_handle() :: pid | {:error, reason}

  def take_handle do
    :pooler.take_member(Dex.JS)
  end

  @spec return_handle(pid) :: :ok 

  def return_handle handle do
    :pooler.return_member(Dex.JS, handle)
  end

  # Server (callbacks)

  def init(_) do
    {:ok, js} = new()
    :ok = load_libs(js)
    :ok = register_functions(js)
    {:ok, %State{js: js}}
  end

  def handle_call({:eval, str, timeout}, _from, state) do
    res = case :js_driver.eval_js(state.js, str, timeout) do
      {:ok, val} -> {:ok, handle_evaluated val}
      {:error, reason} -> {:error, reason}
    end
    {:reply, res, state}
  end

  def handle_call({:call, fun, args}, _from, state) do
    res = case :js.call(state.js, fun, args) do
      {:ok, val} -> {:ok, handle_evaluated val}
      {:error, reason} -> {:error, reason}
    end
    {:reply, res, state}
  end

  def handle_call({:define, str}, _from, state) do
    result = :js.define(state.js, str)
    {:reply, result, state}
  end

  def handle_call(request, from, state) do
    # Call the default implementation from GenServer
    super(request, from, state)
  end

  def handle_cast({:push, item}, state) do
    {:noreply, [item|state]}
  end

  def handle_cast(request, state) do
    super(request, state)
  end

  def terminate(_reason, state) do
    destroy(state.js)
  end

  # Privates

  defp new do
    :js_driver.new
  end

  defp priv_dir do
    :code.priv_dir(Dex.app) |> to_string
  end

  defp load_libs(js) do
    js_path = priv_dir() <> "/js/"
    (conf(Dex.JS)[:libs] || [])
      |> Enum.each(
        &(:ok = do_load_libs(js, js_path) <> &1)
      )
  end

  defp do_load_libs(js, filename) when is_bitstring(filename) do
    do_load_libs(js, String.to_charlist filename)
  end

  defp do_load_libs(js, filename) when is_list(filename) do
    :js_driver.define_js(js, {:file, filename})
  end

  defp register_functions(js) do
    str = "var markdown = function(str){ return marked(str); }"
    :js.define(js, str)
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
    :js_driver.destroy(js)
  end

end

