defmodule Dex.Service.Helper do

  use Dex.Common
  alias Dex.Service.Seater
  alias Dex.Service.App

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end # defmacro

  def do! state, line, fun_name, fun_ref, args \\ [], opts \\ %{} do
    %{state | line: line, fun: fun_name, args: args, opts: opts}
      |> do!(fun_ref) 
  end

  def do! state, {user_id, app_id, fun} do
    with \
      app_id = (app = state.app.uses[app_id]) && app.id || app_id,
      {:ok, {app, module}} <- Seater.take_app(user_id, app_id),
      %App.Fun{no: no} = (app.funs[fun] 
        || raise Error.FunctionNotFound, state: %{state | fun: fun})
    do state
      |> do_do!(fn s_ -> apply(module, no_to_fn(no), [s_]) |> result end)
    else
      {:error, reason} ->
        IO.inspect reason: reason
        raise Error.FunctionCallError, reason: reason, state: state
    end
  end

  def do!(state, fn_) when is_function(fn_) do
    state
      |> do_do!(fn s_ -> fn_.(s_) |> result end)
  end

  defp do_do! state, fn_ do
    try do
      state |> check |> fn_.()
    rescue ex ->
      #IO.inspect ex
      handle_exception ex, state
    catch :throw, error ->
      handle_throw error, state
    end
  end

  defp handle_throw {:error, reason}, state do
    reason = inspect reason
    raise Error.RuntimeError, reason: reason, state: state
  end

  defp handle_throw {error, reason}, state do
    error = to_string error
    reason = inspect reason
    raise Error.RuntimeError, reason: [error, reason], state: state
  end

  defp handle_throw error, state do
    error = inspect error
    raise Error.RuntimeError, reason: error, state: state
  end

  @max_depth 100_000

  defp check state do
    state |> do_check(:depth)
  end

  defp do_check state = %{depth: depth}, :depth do
    (depth >= @max_depth)
      && (raise Error.FunctionDepthOver, reason: depth, state: state)
      || %{state | depth: depth + 1}
  end

  defp cleanup state do
    state |> do_cleanup(:depth)
  end

  defp do_cleanup state = %{depth: depth}, :depth do
    %{state | depth: depth - 1}
  end


  defmacro val! "true", _    do true end
  defmacro val! "false", _   do false end
  defmacro val! "nil", _     do nil end

  defmacro val! str, state do
    inspected = Mappy.parse_var! str
    quote do: Dex.val(unquote(state).dex, unquote(inspected), nil)
  end

  _ = ~S"""
  defp print state, :line do
    IO.puts "=LINE: #{state.line}"
    state
  end

  defp print state, :code do
    IO.puts "\n=PARSED CODES=================================\n"
    IO.puts state.script.parsed |> String.rstrip
    IO.puts "\n=TRANSLATED CODES=============================\n"
    IO.puts state.script.translated |> String.rstrip
    state
  end
  """

  defp handle_exception ex = %FunctionClauseError{}, state do
    case (to_string ex.function) do
      "do_" <> _ ->
        raise Error.InvalidArgument, state: state
      fun ->
        if (String.starts_with? fun, state.fun),
          do: (raise Error.BadArity, state: state),
          else: (reraise ex, System.stacktrace)
    end
  end

  defp handle_exception %UndefinedFunctionError{}, state do
    raise Error.FunctionNotFound, state: state
  end

  defp handle_exception ex = %ArithmeticError{}, state do
    raise Error.ArithmeticError, reason: ex.message, state: state
  end

  defp handle_exception ex = %Protocol.UndefinedError{}, state do
    IO.inspect ex
    js_ex = Dex.JSON.decode!(ex.value)
    state = %{state | line: state.line + js_ex["lineno"] + 1}
    reraise Error.JavascriptError,
      [reason: js_ex["error"], state: state], System.stacktrace
  end

  defp handle_exception ex, _state do
    reraise ex, System.stacktrace
  end

  def set_args state = %{dex: dex, args: args}, params do
    p_args = Enum.zip(params, args) |> Enum.into(%{})
    dex = Dex.merge(dex, p_args)
    %{state | dex: dex}
  end

  def set_opts state = %{dex: dex, opts: nil}, kv_list do
    dex = Enum.reduce kv_list, dex, fn {k, defv}, acc ->
      Dex.set(acc, k, defv)
    end
    %{state | dex: dex}
  end

  def set_opts state = %{dex: dex, opts: opts}, kv_list do
    dex = Enum.reduce kv_list, dex, fn {k, defv}, acc ->
      v = Map.get(opts, k, defv)
      Dex.set(acc, k, v)
    end
    %{state | dex: dex}
  end

  defp result {state, :null} do result {state, nil} end
  defp result {state, data} do state |> cleanup |> set_data(data) end
  defp result state do state |> cleanup end

  defp no_to_fn no do
    "_F#{no}" |> String.to_existing_atom
  end

  def run_javascript state, script, args do
    try do
      script = "(#{script}).apply(null,#{Dex.JSON.encode! args});"
      case Dex.JS.eval(state.js, script) do
        {:ok, res} -> {state, res}
        {:error, err} -> throw Enum.into(err, %{})
      end
    catch :throw, js ->
      state = %{state | line: state.line + js["lineno"] - 1}
      raise Error.JavascriptError, reason: js["message"], state: state
    rescue ex ->
      handle_exception ex, state
    end
  end

  def auth_basic! state = %{user: user, req: req} do
    with \
      false <- state.authorized && :authorized,
      "Basic " <> base64 <- req.header["authorization"],
      {:ok, decoded} <- Base.decode64(base64),
      true <- user && user.__secret == sha256(decoded)
    do
      %{state | authorized: true}
    else
      :authorized -> state
      _ -> raise Error.Unauthorized, code: 401, state: state
    end
  end

  def set_data state = %{dex: dex}, val do
    dex = Dex.set dex, "data", val
    %{state | dex: dex}
  end

  def data! %{dex: dex} do
    Dex.val dex, "data"
  end

  def arg_data state = %{args: []} do data! state end
  def arg_data %{args: [arg | _]}  do arg end

  def args_data state = %{args: []} do [data! state] end
  def args_data %{args: args}       do args end

end
