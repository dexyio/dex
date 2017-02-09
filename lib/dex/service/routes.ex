defmodule Dex.Service.Routes do

  use Dex.Common
  use Dex.Service.Plugins
  alias Dex.Service.App

  def fn! name, state do
    with \
      :notfound <- check_userdef_fn(name, state),
      :notfound <- check_userlib_fn(name, state),
      :notfound <- check_builtin_fn(name, state)
    do
      raise Error.FunctionNotFound, state: %{state | fun: name}
    end
  end

  defp check_userdef_fn name, _state = %{app: app} do
    case app.funs[name] do
      %App.Fun{no: no} -> "&_F#{Integer.to_string(no)}/1"
      _ -> :notfound
    end
  end

  defp check_userlib_fn name, state do
    case String.split(name, ".", parts: 2) do
      [^name] -> :notfound
      [as, fun_name] ->
        if (app = state.uses[as]) do
          (fun = app.funs[fun_name]) || (raise Error.FunctionNotFound,
            state: %{state | fun: name})
          (right_access? state.user, app, fun) || (raise Error.AccessDenied,
            state: %{state | fun: name})
          {app.owner, app.id, fun_name} |> inspect
        else
          :notfound
        end
    end
  end

  defp check_builtin_fn name, state do
    route! name, state
  end

  defp right_access? user, app, fun do
    case user == app.owner do
      true -> fun.access in [:public, :protected]
      false -> fun.access == :public
    end
  end

  defp route! str, state do
    try do
      case String.split str, ~R/\.(?=[\w\-]+$)/, parts: 2 do
        [fun] -> do_route! fun
        [app, fun] -> do_route! app, fun
      end
    catch
      {:notfound, str} ->
        raise Error.FunctionNotFound, state: %{state | fun: str}
    end
  end

  defp do_route! "nil"           do "&Core.nil_/1" end
  defp do_route! "true"          do "&Core.true_/1" end
  defp do_route! "false"         do "&Core.false_/1" end
  defp do_route! "if"            do "&Core.if_/1" end
  defp do_route! "unless"        do "&Core.unless_/1" end
  defp do_route! "for"           do "&Core.for_/1" end
  defp do_route! "is_nil"        do "&Core.is_nil_/1" end
  defp do_route! "is_number"     do "&Core.is_number_/1" end
  defp do_route! "is_integer"    do "&Core.is_integer_/1" end
  defp do_route! "is_float"      do "&Core.is_float_/1" end
  defp do_route! "is_boolean"    do "&Core.is_boolean_/1" end
  defp do_route! "is_list"       do "&Core.is_list_/1" end
  defp do_route! "is_map"        do "&Core.is_map_/1" end
  defp do_route! "is_tuple"      do "&Core.is_tuple_/1" end
  defp do_route! "div"           do "&Core.div_/1" end
  defp do_route! "rem"           do "&Core.rem_/1" end
  defp do_route! "abs"           do "&Core.abs_/1" end
  defp do_route! "round"         do "&Core.round_/1" end
  defp do_route! "trunc"         do "&Core.trunc_/1" end
  defp do_route!(fun)            do do_route! "core", fun end

  defp do_route!(app, fun) do
    try do
      app = String.to_existing_atom app
      (mod = conf(Dex.Service.Plugins)[app]) |> Elixir.Code.ensure_loaded 
      fun = String.to_existing_atom(fun)
      (function_exported? mod, fun, 1) |> case do 
        true -> "&#{short_mod mod}.#{fun}/1"
        false ->
          case (function_exported? mod, :on_call, 1) do
            true -> "&#{short_mod mod}.on_call/1"
            false -> throw {:notfound, mod <> "." <> fun}
          end
      end
    rescue
      ArgumentError -> throw {:notfound, fun}
    end
  end

  @spec short_mod(atom) :: bitstring
  defp short_mod module do
    (module |> to_string |> String.split(".") |> List.last) || "Core"
  end

end

