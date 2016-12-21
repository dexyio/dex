defmodule Dex.JS do

  @adapter Application.get_env(:dex, __MODULE__)[:adapter]

  @type handle :: pid | {pid, context}
  @type context :: pos_integer
  @type error :: {:error, reason}
  @type reason :: term

  defmodule Adapter do
    alias Dex.JS
    @callback start_link(Keyword.t) :: {:ok, pid} | JS.error
    @callback eval(pid, bitstring, pos_integer) :: {:ok, term} | JS.error
    @callback call(pid, fun, list, pos_integer) :: {:ok, term} | JS.error
    @callback take_handle() :: {:ok, pid} | JS.error
    @callback return_handle(pid) :: term
  end

  defdelegate start_link(args \\ []), to: @adapter
  defdelegate eval(handle, script, timeout \\ 5000), to: @adapter
  defdelegate call(handle, fun, args, timeout \\ 5000), to: @adapter
  defdelegate take_handle(), to: @adapter
  defdelegate return_handle(handle), to: @adapter

  @spec eval!(handle, bitstring) :: term | error

  def eval! handle, script do
    case eval handle, script do
      {:ok, val} -> val
      {:error, reason} -> throw {:error, reason}
    end
  end

  @spec call!(handle, bitstring, list) :: term | error

  def call! handle, fun, args do
    case call handle, fun, args do
      {:ok, val} -> val
      {:error, reason} -> throw {:error, reason}
    end
  end

  @spec eval_script!(handle, bitstring, list) :: term | error

  def eval_script! handle, script, args \\ []  do
    script = "(function() {#{script}}).apply(null, #{DexyLib.JSON.encode! args});"
    eval! handle, script
  end

  @spec to_jstr(any) :: term

  def to_jstr(a..b) do
    to_jstr(Enum.to_list a..b)
  end

  def to_jstr(data) when is_map(data) do
    list = Enum.into(data, [], fn {key, val} ->
      "'" <> to_string(key) <> "':" <> to_jstr(val)
    end)
    "{" <> Enum.join(list, ",") <> "}"
  end

  def to_jstr(data) when is_list(data) do
    list = Enum.into(data, [], fn val ->
      to_jstr(val)
    end) 
    "[" <> Enum.join(list, ",") <> "]"
  end
 
  def to_jstr(data) when is_bitstring(data) do
    "\"" <> data <> "\""
  end

  def to_jstr({key, val}) do
    to_jstr(%{key => val})
  end

  def to_jstr(nil) do
    "null"
  end

  def to_jstr(data) do
    to_string data
  end

end
