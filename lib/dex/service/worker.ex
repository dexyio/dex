defmodule Dex.Service.Worker do

  use GenServer
  use Dex.Common
  use Dex.Service.Helper
  alias Dex.Service.User
  alias Dex.Service.App
  alias Dex.Service.Request
  alias Dex.Service.Seater
  require Dex.Service.Code
  #import Logger

  alias Dex.Service.State

  @spec start_link(Proplists.t) :: {:ok, pid} | {:error, term}

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, new_state, args)
  end

  @spec new_state() :: %Dex.Service.State{}

  def new_state do
    %Dex.Service.State{
      dex: Dex.new,
      js: Dex.JS.take_handle
    }
  end

  @spec ping(pid) :: :pong

  def ping(worker) do
    GenServer.call(worker, :ping)
  end

  @spec play(pid, %User{}, %Request{}) :: term

  def play(worker, user, req) do
    GenServer.cast(worker, {:play, user, req})
  end

  # callback functions

  def handle_call(:ping, _, state) do
    {:reply, :pong, state}
  end

  def handle_cast({:play, user, req}, state) do
    do_play %{state | user: user, req: req}
    {:stop, :normal, state}
  end

  # private functions

  defp do_play state do
    try do
      state
      #|> check_user!
        |> check_app!
        |> set_vars
        |> play!
        |> reply!
    rescue
      ex in Error.Stopped -> 
        reply! ex.state
      ex ->
        #IO.inspect ex; IO.inspect System.stacktrace
        state2 = (struct_to_map(ex)[:state] || state) |> struct_to_map
        %{
          error: ex.message, 
          code: ex.code || Code.bad_request,
          message: ex.reason, 
          line: state2[:line], 
          fun: state2[:fun],
          args: state2[:args],
          opts: state2[:opts]
        }
        |> reply_error!(state.req)
    end
  end

  defp check_app! state = %State{req: req} do
    {user_id, app_id} =
      case req.app do
        app_id = "_" <> _ -> {"*", app_id}
        app_id -> {req.user, app_id}
      end
    case Seater.take_app user_id, app_id do
      {:ok, {app, mod}} -> check_auth! %{state | app: app, mod: mod}
      {:error, :app_notfound} -> raise Error.AppNotFound,
        code: Code.not_found, reason: req.app, state: state
      {:error, reason} -> raise Error.AppLoadingFailed,
        reason: reason, state: state
    end
  end
 
  defp check_auth! state = %State{app: app} do
    app.export && state || auth_basic! state
  end
  
  defp set_vars state = %State{req: req} do
    dex = state.dex
      |> Dex.set("req.peer", req.peer)
      |> Dex.set("req.app", req.app)
      |> Dex.set("req.fun", req.fun |> String.downcase)
      |> Dex.set("req.args", req.args)
      |> Dex.set("req.opts", req.opts)
      |> Dex.set("req.header", req.header)
      |> Dex.set("req.body", req.body)
      |> Dex.merge(req.vars)
    %{state | dex: dex, args: req.args, opts: req.opts}
  end

  defp play! state = %State{req: req, app: app, mod: mod} do
    fun = req.fun |> String.downcase |> real_fun(app)
      || real_fun("error", app)
      || raise Error.FunctionNotFound,
               code: 404, state: %{state | fun: req.fun}
    apply(mod, fun, [state])
  end

  defp real_fun fun_name, app do
    case app.funs[fun_name] do
      %App.Fun{} = fun -> "_F#{fun.no}" |> String.to_existing_atom
      nil -> nil
    end
  end

  defp reply! %{dex: dex, req: req} do
    result_data = Dex.val(dex, "data")
    send req.callback, {req.id, {:ok, result_data}}
  end

  defp reply_error! ex, %{callback: cb_pid, id: req_id} do
    send cb_pid, {req_id, {:error, ex}}
  end

  defp struct_to_map struct = %{__struct__: _} do
    Map.from_struct struct
  end

  defp struct_to_map(map) when is_map(map) do
    map
  end

  def terminate(_reason, state) do
    Dex.JS.return_handle state.js
  end

end

