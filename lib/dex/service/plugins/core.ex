defmodule Dex.Service.Plugins.Core do

  use Dex.Common
  use Dex.Service.Helper
  alias Dex.Service.Seater
  alias Dex.Service.App

  @type state :: %Dex.Service.State{}

  @doc ~S"""
  ## Examples

      iex> Dex.Test.do! '''
      ...> <data>
      ...>   | set nil  | assert nil
      ...>   | nil      | assert nil
      ...> </data>
      ...> '''
      nil

  """
  @spec nil_(state) :: {state, nil}

  def nil_ state do {state, nil} end

  @doc ~S"""
  ## Examples

      iex> Dex.Test.do! '''
      ...> <data>
      ...>   | set true | assert true
      ...>   | true     | assert true
      ...> </data>
      ...> '''
      true

  """
  @spec true_(state) :: {state, true}

  def true_ state do {state, true} end

  @doc ~S"""
  ## Examples

      iex> Dex.Test.do! '''
      ...> <data>
      ...>   | set false | assert false
      ...>   | false     | assert false
      ...> </data>
      ...> '''
      false

  """
  @spec false_(state) :: {state, false}

  def false_ state do {state, false} end

  @spec flatten(state) :: {state, list}

  def flatten state = %{args: []} do do_flatten state, data! state end
  def flatten state = %{args: [data]} do do_flatten state, data end

  defp do_flatten(state, data) when is_list(data) do
    {state, List.flatten data}
  end

  @spec add(state) :: {state, term}

  def add state = %{args: []} do
    state
  end

  @spec to_binary(state) :: {state, binary}

  def to_binary state = %{args: []} do do_to_binary state, data! state end
  def to_binary state = %{args: [data]} do do_to_binary state, data end

  defp do_to_binary(state, data) do {state, BIF.to_binary data} end

  @spec to_term(state) :: {state, term}

  def to_term state = %{args: []} do do_to_term state, data! state end
  def to_term state = %{args: [data]} do do_to_term state, data end

  defp do_to_term(state, data) when is_binary(data) do
    {state, BIF.binary_to_term data}
  end

  defp do_to_term(state, data) do {state, data} end

  @doc ~S"""
  ## Examples

      iex> Dex.Test.do! '''
      ...> <data>
      ...>   | set 0            | to_list | assert [0]
      ...>   | set 123          | to_list | assert [1, 2, 3]
      ...>   | set {}           | to_list | assert []
      ...>   | set {1, 2, 3}    | to_list | assert [1, 2, 3]
      ...>   | set {:}          | to_list | assert []
      ...>   | set {a: 1, b: 2} | to_list | assert [{"a", 1}, {"b", 2}]
      ...>   | set ""           | to_list | assert []
      ...>   | set "foo"        | to_list | assert ["f", "o", "o"]
      ...>   | set nil          | to_list | assert []
      ...> </data>
      ...> '''
      []

  """
  @spec to_list(state) :: {state, list}

  def to_list state = %{args: []} do do_to_list state, data! state end
  def to_list state = %{args: [data]} do do_to_list state, data end

  defp do_to_list(state, data) when is_tuple(data) do
    {state, Tuple.to_list data}
  end

  defp do_to_list(state, data) when is_bitstring(data) do
    {state, String.codepoints data}
  end

  defp do_to_list(state, data) when is_map(data) do
    {state, Enum.to_list data}
  end

  defp do_to_list(state, data) when is_number(data) do
    {state, Integer.digits data}
  end

  defp do_to_list(state, data) when is_list(data) do
    {state, data}
  end

  defp do_to_list(state, nil) do
    {state, []}
  end

  @doc ~S"""
  ## Examples

      iex> Dex.Test.do! '''
      ...> <data>
      ...> </data>
      ...> '''
      nil

  """
  @spec map(state) :: {state, map}

  def map state = %{opts: opts} do
    {state, opts}
  end

  @spec to_tuple(state) :: {state, tuple}

  def to_tuple state = %{args: []} do do_to_tuple state, data! state end
  def to_tuple state = %{args: [data]} do do_to_tuple state, data end

  defp do_to_tuple(state, data = _.._) do
    res = Enum.into(data, []) |> List.to_tuple
    {state, res}
  end

  defp do_to_tuple(state, data) when is_list(data) do
    {state, List.to_tuple data}
  end

  defp do_to_tuple(state, data) when is_tuple(data) do
    state
  end

  @spec to_number(state) :: {state, number}

  def to_number state = %{args: []} do do_to_number state, data! state end
  def to_number state = %{args: [data]} do do_to_number state, data end

  defp do_to_number(state, data) when is_bitstring(data) do
    {state, BIF.to_number data}
  end

  @spec to_string(state) :: {state, bitstring}

  def to_string state = %{args: []} do do_to_string state, data! state end
  def to_string state = %{args: [data]} do do_to_string state, data end

  defp do_to_string(state, nil) do {state, ""} end
  defp do_to_string(state, data) when is_bitstring(data) do state end
  defp do_to_string(state, data) do {state, Kernel.to_string data} end

  @spec is_nil_(state) :: {state, boolean}

  def is_nil_ state do
    {state, is_nil arg_data(state)}
  end

  @spec is_boolean_(state) :: {state, boolean}

  def is_boolean_ state do
    {state, is_boolean arg_data(state)}
  end

  @spec is_number_(state) :: {state, boolean}

  def is_number_ state do
    {state, is_number arg_data(state)}
  end

  @spec is_integer_(state) :: {state, boolean}

  def is_integer_ state do
    {state, is_integer arg_data(state)}
  end

  @spec is_float_(state) :: {state, boolean}

  def is_float_ state do
    {state, is_float arg_data(state)}
  end

  @spec is_string_(state) :: {state, boolean}

  def is_string_ state do
    {state, is_bitstring arg_data(state)}
  end

  @spec is_tuple_(state) :: {state, boolean}

  def is_tuple_ state do
    {state, is_tuple arg_data(state)}
  end

  @spec is_list_(state) :: {state, boolean}

  def is_list_ state do
    {state, is_list arg_data(state)}
  end

  @spec is_map_(state) :: {state, boolean}

  def is_map_ state do
    {state, is_map arg_data(state)}
  end

  @spec is_range_(state) :: {state, boolean}

  def is_range_ state do
    {state, Range.range? arg_data(state)}
  end

  @spec is_regex_(state) :: {state, boolean}

  def is_regex_ state do
    {state, Regex.regex? arg_data(state)}
  end

  @spec join(state) :: {state, term}

  def join state = %{args: []} do do_join state, data!(state), "" end
  def join(state = %{args: [data]}) when not is_bitstring(data) do do_join state, data, "" end
  def join state = %{args: [joiner]} do do_join state, data!(state), joiner end
  def join(state = %{args: [data, joiner]}) do do_join state, data, joiner end

  defp do_join(state, data, joiner) when is_list(data) and is_bitstring(joiner) do
    {state, Enum.join(data, joiner)}
  end

  defp do_join(state, a..b, joiner) when is_bitstring(joiner) do
    {state, Enum.join(a..b, joiner)}
  end

  defp do_join(state, data, joiner) when is_tuple(data) and is_bitstring(joiner) do
    res = data |> Tuple.to_list |> Enum.join(joiner)
    {state, res}
  end

  @spec first(state) :: {state, term}

  def first state = %{args: []} do do_first state, data!(state) end
  def first state = %{args: [data]} do do_first state, data end

  defp do_first(state, data) when is_bitstring(data) do
    {state, String.first data}
  end

  defp do_first(state, data) when is_list(data) or is_map(data) do
    {state, Enum.at(data, 0)}
  end

  defp do_first(state, data) when is_tuple(data) do
    do_first state, Tuple.to_list data
  end

  @spec last(state) :: {state, term}

  def last state = %{args: []} do do_last state, data!(state) end
  def last state = %{args: [data]} do do_last state, data end

  defp do_last(state, data) when is_bitstring(data) do
    {state, String.last data}
  end

  defp do_last(state, data) when is_list(data) or is_map(data) do
    {state, Enum.at(data, -1)}
  end

  defp do_last(state, data) when is_tuple(data) do
    do_last state, Tuple.to_list data
  end
  
  @spec div_(state) :: {state, number}

  def div_ state = %{args: [val]} do do_div state, data!(state), val end
  def div_ state = %{args: [data, val]} do do_div state, data, val end

  defp do_div(state, data, by_val) \
    when is_number(data) and is_number(by_val)
  do
    {state, div(data, by_val)}
  end

  @spec rem_(state) :: {state, number}

  def rem_ state = %{args: [val]} do do_rem state, data!(state), val end
  def rem_ state = %{args: [data, val]} do do_rem state, data, val end

  defp do_rem(state, data, by_val) \
    when is_number(data) and is_number(by_val)
  do
    {state, rem(data, by_val)}
  end

  @spec round_(state) :: {state, number}

  def round_ state = %{args: []} do do_round state, data! state end
  def round_ state = %{args: [data]} do do_round state, data end

  defp do_round(state, data) when is_number(data) do
    {state, round data}
  end

  @spec trunc_(state) :: {state, number}

  def trunc_ state = %{args: []} do do_trunc state, data! state end
  def trunc_ state = %{args: [data]} do do_trunc state, data end

  defp do_trunc(state, data) when is_number(data) do
    {state, trunc data}
  end

  @spec ceil(state) :: {state, number}

  def ceil state = %{args: []} do do_ceil state, data! state end
  def ceil state = %{args: [data]} do do_ceil state, data end

  defp do_ceil(state, data) when is_float(data) do
    {state, Float.ceil data}
  end

  defp do_ceil(state, data) when is_number(data) do
    state
  end

  @spec floor(state) :: {state, number}

  def floor state = %{args: []} do do_floor state, data! state end
  def floor state = %{args: [data]} do do_floor state, data end

  defp do_floor(state, data) when is_float(data) do
    {state, Float.floor data}
  end

  defp do_floor(state, data) when is_number(data) do
    state
  end
  
  @spec abs_(state) :: {state, number}

  def abs_ state = %{args: []} do do_abs state, data! state end
  def abs_ state = %{args: [data]} do do_abs state, data end

  defp do_abs(state, data) when is_number(data) do
    {state, abs data}
  end

  @spec at(state) :: {state, term}

  def at state = %{args: [idx]} do
    do_at state, data!(state), idx
  end

  def at state = %{args: [val, idx]} do
    do_at state, val, idx
  end

  defp do_at(state, val, idx) when is_number(idx) do
    {state, BIF.at(val, idx)}
  end

  @spec set(state) :: state

  def set state = %{args: [], opts: opts} do
    do_set state, opts
  end

  def set state = %{args: [data | _], opts: opts} do
    opts = Map.put opts, "data", data
    do_set state, opts
  end

  defp do_set state = %{dex: dex}, opts do
    dex = Enum.reduce opts, dex, fn {k, v}, acc ->
      Dex.set(acc, k, v)
    end
    %{state | dex: dex}
  end

  @spec val(state) :: {state, term}

  def val state = %{args: [val], opts: opts} do
    {state, val || opts["default"]}
  end

  @spec assert(state) :: state

  def assert state = %{args: [arg | _], opts: opts} do
    assert %{state | args: [], opts: Map.put(opts, "data", arg)}
  end

  def assert state = %{dex: dex, args: [], opts: opts} do
    case do_assert(opts |> Map.to_list, dex) do
      true -> state
      {k, v} -> raise Error.AssertionFailed, reason: [k, v], state: state
    end
  end

  defp do_assert [], _dex do true end

  defp do_assert [{k, v} | rest], dex do
    case Dex.val dex, k do
      ^v -> do_assert rest, dex
      val when v == true -> val && do_assert(rest, dex) || {k, val}
      val when v == false -> !val && do_assert(rest, dex) || {k, val}
      val -> {k, val}
    end
  end

  defp cond_ state = %{args: []}, _expected do
    state
  end

  defp cond_ state = %{args: [{fn_args, fn_opts, fn_} | rest]}, expected do
    args = fn_args.(state)
    opts = fn_opts.(state)
    cond_ state, expected, [{args, opts, fn_} | rest]
  end

  defp cond_ state, expected, [{[], conds, fn_} | rest] do
    if conds == %{} do
      fn_.(state)
    else
      case BIF.compare?(conds, state.dex) do
        ^expected -> fn_.(state)
        _ -> cond_ %{state | args: rest}, expected
      end
    end
  end
    
  defp cond_ state, expected, [{[data], conds, fn_} | rest] do
    conds = Map.put(conds, "data", data)
    cond_ state, expected, [{[], conds, fn_} | rest]
  end

  @spec if_(state) :: state

  def if_ state do
    cond_ state, true
  end

  @spec unless_(state) :: state

  def unless_ state do
    cond_ state, false
  end

  @spec case(state) :: state

  def case state = %{args: [_fn_true | rest]} do
    cond_ %{state | args: rest}, true
  end

  @spec filter(state) :: {state, term}

  def filter(state = %{args: [{fn_args, _fn_opts, fn_do}]}) \
    when is_function(fn_args) 
  do
    args = fn_args.(state)
    filter state, args, fn_do
  end

  defp filter state, [], fn_do do do_filter state, data!(state), fn_do end
  defp filter state, [data], fn_do do do_filter state, data, fn_do end

  defp do_filter(state, data, fn_do) when is_list(data) or is_map(data) do
    res = Enum.filter data, fn x ->
      set_data(state, x) |> fn_do.() |> data!
    end
    {state, res}
  end

  defp do_filter(state, data, fn_do) when is_tuple(data) do
    do_filter state, (Tuple.to_list data), fn_do
  end

  defp do_filter(state, data, fn_do) when is_number(data) do
    do_filter state, 1..data, fn_do
  end

  defp do_filter(state, data, fn_do) when is_bitstring(data) do
    do_filter state, (data |> String.codepoints), fn_do
  end

  @spec for_(state) :: {state, term}

  def for_(state = %{args: [{fn_args, _fn_opts, fn_} | rest]})
    when is_function(fn_args)
  do
    rest = rest ++ [{fn(_) -> [] end, fn(_) -> %{} end, fn_}]
    data = fn_args.(state)
      |> case do
        [] -> data!(state)
        [data] -> data
        _ -> raise Error.BadArity, state: state
      end
    do_for %{state | args: rest}, data
  end

  def for_ state = %{args: []} do
    do_for state, data!(state)
  end

  def for_ state = %{args: [data]} do
    do_for %{state | args: []}, data
  end

  defp do_for(state, data) when is_list(data) or is_map(data) do
    {res, state2} =
      Enum.map_reduce data, state, fn x, s ->
        s = set_data(s, x) |> cond_(true)
        {data!(s), %{state | dex: s.dex}}
      end
    {state2, res}
  end

  defp do_for(state, data) when is_tuple(data) do
    do_for state, (Tuple.to_list data)
  end

  defp do_for(state, data) when is_number(data) do
    do_for state, 1..data
  end

  defp do_for(state, data) when is_bitstring(data) do
    do_for state, (data |> String.codepoints)
  end

  @spec split(state) :: {state, term}

  def split state = %{args: [], opts: opts} do
    do_split state, data!(state), ~r/\s+/, opts
  end

  def split state = %{args: [token], opts: opts} do
    do_split state, data!(state), token, opts
  end

  def split state = %{args: [data, token], opts: opts} do
    do_split state, data, token, opts
  end

  defp do_split(state, data, token, opts) when is_bitstring(data) do
    opts = (parts = opts["parts"]) && [parts: parts] || []
    {state, String.split(data, token, opts)}
  end

  defp do_split(state, data, count, _opts) when is_map(data) or is_list(data) do
    is_number(count) || raise Error.InvalidArgument, state: state
    {state, Enum.split(data, count)}
  end

  @spec lines(state) :: {state, list}

  def lines(state = %{args: [], opts: opts}) do
    do_lines state, data!(state), opts
  end

  def lines(state = %{args: [data], opts: opts}) do
    do_lines state, data, opts
  end

  defp do_lines(state, data, opts) when is_bitstring(data) do
    limit = opts["limit"]; trim = opts["trim"]
    opts = limit && is_number(limit) && [parts: limit] || []
    opts = trim || opts && [{:trim, true} | opts]
    res = BIF.lines data, opts
    {state, res}
  end

  @spec count(state) :: {state, number}

  def count state = %{args: []} do {state, BIF.count data!(state)} end
  def count state = %{args: [data]} do {state, BIF.count data} end

  @spec stop(state) :: Dex.Error.Stopped

  def stop state do
    raise Error.Stopped, state: state
  end

  def use state = %{opts: opts} do
    data = arg_data(state) |> String.trim_leading
    do_use state, data, opts["as"]
  end

  defp do_use state, _, nil do
    raise Error.AppAliasOmitted, state: state
  end

  defp do_use state = %{req: req}, script, as do
    app = App.parse! req.user, script
    app_id = req.app <> ":" <> as
    uses = (app.uses || %{}) |> Map.put(as, app_id)
    app = %{app | owner: req.user, id: app_id, uses: uses}
    state = %{state | app: app}
    case Seater.alloc_app app do
      {:ok, _module} -> {state, "ok"}
      {:error, reason} -> raise Error.AppAllocationFailed,
        reason: reason, state: state
    end
  end

  def apply state = %{opts: opts} do
    appfun = arg_data(state) |> String.split(".", parts: 2)
      |> case do
        [app] -> {app, "get"}
        [app, fun] -> {app, fun}
      end
    apply_args = opts["args"] || []
    apply_opts = opts["opts"] || %{}
    do_apply state, appfun, apply_args, apply_opts
  end

  defp do_apply state, {app, fun}, args, opts do
    do! state, state.line, "", {state.req.user, app, fun}, args, opts
  end

  def length state = %{args: []} do do_length state, data! state end
  def length state = %{args: [data]} do do_length state, data end

  defp do_length state, data do
    {state, BIF.length data}
  end

  def is_true state = %{args: []} do do_is_true state, data! state end
  def is_true state = %{args: [data]} do do_is_true state, data end

  defp do_is_true state, data do
    {state, data && true || false}
  end

  def is_blank state = %{args: []} do do_is_blank state, data! state end
  def is_blank state = %{args: [data]} do do_is_blank state, data end

  defp do_is_blank(state, data) \
    when data in [nil, 0, [], %{}, {}, "", '']
  do
    {state, true}
  end

  defp do_is_blank(state, _data) do {state, false} end

  def trim state = %{args: [], opts: opts} do
    do_trim state, data!(state), opts["off"] || ""
  end

  def trim state = %{args: [data], opts: opts} do
    do_trim state, data, opts["off"] || ""
  end

  def trim state = %{args: [data, off]} do
    do_trim state, data, off
  end

  defp do_trim(state, data, "") when is_bitstring(data) do
    {state, String.trim data}
  end

  defp do_trim(state, data, off) when is_bitstring(data) and is_bitstring(off) do
    {state, String.trim(data, off)}
  end

  def ltrim state = %{args: []} do do_ltrim state, data! state end
  def ltrim state = %{args: [data]} do do_ltrim state, data end

  defp do_ltrim(state, data) when is_bitstring(data) do
    {state, String.trim_leading data}
  end

  def rtrim state = %{args: []} do do_rtrim state, data! state end
  def rtrim state = %{args: [data]} do do_rtrim state, data end

  defp do_rtrim(state, data) when is_bitstring(data) do
    {state, String.trim_trailing data}
  end
  def upcase state do
    res = BIF.upcase arg_data(state)
    {state, res}
  end

  def downcase state do
    res = BIF.downcase arg_data(state)
    {state, res}
  end

  def bytes state do
    res = BIF.bytes arg_data(state)
    {state, res}
  end

  def slice state = %{args: args = [_]} do do_slice state, args end
  def slice state = %{args: args = [_, _]} do do_slice state, args end
  def slice state = %{args: args = [_, _, _]} do do_slice state, args end

  defp do_slice state, [range = _.._] do
    res = BIF.slice data!(state), range
    {state, res}
  end

  defp do_slice state, [data, range = _.._] do
    res = BIF.slice data, range
    {state, res}
  end

  defp do_slice(state, [at, cnt]) when is_number(at) and is_number(cnt) do
    res = BIF.slice data!(state), at, cnt
    {state, res}
  end

  defp do_slice(state, [data, at, cnt]) when is_number(at) and is_number(cnt) do
    res = BIF.slice data, at, cnt
    {state, res}
  end

  def sum state = %{args: []} do do_sum state, data!(state) end
  def sum state = %{args: [data]} do do_sum state, data end

  defp do_sum(state, data = _.._) do {state, Enum.sum data} end
  defp do_sum(state, data) when is_list(data) do {state, Enum.sum data} end

  def reverse state = %{args: []} do do_reverse state, data!(state) end
  def reverse state = %{args: [data]} do do_reverse state, data end

  defp do_reverse(state, data) do
    {state, BIF.reverse data}
  end

  def take state = %{args: []} do do_take state, data!(state), 1 end
  def take state = %{args: [cnt]} do do_take state, data!(state), cnt end
  def take state = %{args: [data, cnt]} do do_take state, data, cnt end

  defp do_take(state, data, cnt) when is_number(cnt) do
    {state, BIF.take(data, cnt)}
  end

  def chiwoo state = %{args: [a]}do
    {state, a+1}
  end

end

