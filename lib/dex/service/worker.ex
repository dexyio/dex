defmodule Dex.Service.Worker do

  use GenServer
  use Dex.Common
  use Dex.Service.Helper
  alias DexyLib.Mappy
  alias Dex.Service.User
  alias Dex.Service.App
  alias Dex.Service.Request
  alias Dex.Service.Seater
  require Dex.Service.Code
  #import Logger

  alias Dex.Service.State

  @spec start_link(Proplists.t) :: {:ok, pid} | {:error, term}

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, new_state(), args)
  end

  @spec new_state() :: %Dex.Service.State{}

  def new_state do
    %Dex.Service.State{
      mappy: Mappy.new,
      js: nil#Dex.JS.take_handle
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
    req = %{req | fun: String.downcase req.fun}
    do_play %{state | user: user, req: req}
    {:stop, :normal, state}
  end

  # private functions

  defp do_play state do
    try do
      state
        |> check_app!
        |> set_vars
        |> play!
        |> reply!
    rescue
      ex in Error.Stopped -> 
        reply! ex.state
      ex ->
        #IO.inspect ex
        #IO.inspect System.stacktrace
        ex_map = struct_to_map(ex)
        state2 = (ex_map[:state] || state) |> struct_to_map
        %{
          error: ex_map[:message] || "RuntimeError",
          code: ex_map[:code] || Code.bad_request,
          message: (if ex_map[:state], do: ex.reason, else: inspect ex),
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
        app_id -> {req.user, app_id || ""}
      end
    case Seater.take_app user_id, app_id do
      {:ok, {app, mod}} -> check_auth! %{state | app: app, mod: mod}
      {:error, :app_notfound} -> raise Error.AppNotFound,
        code: Code.not_found, reason: req.app, state: state
      {:error, reason} -> raise Error.AppLoadingFailed,
        reason: reason, state: state
    end
  end
 
  defp check_auth! state = %State{req: req, app: app} do
    case app.funs[req.fun] do
      nil -> state
      %{access: :public} -> state
      %{access: :protected} -> auth_basic! state
      _private -> raise Error.FunctionNotFound, state: %{state | fun: req.fun}
    end
  end
  
  defp set_vars state = %State{req: req} do
    map = state.mappy
      |> Mappy.set("req.peer", req.peer)
      |> Mappy.set("req.app", req.app)
      |> Mappy.set("req.fun", req.fun)
      |> Mappy.set("req.args", req.args)
      |> Mappy.set("req.opts", req.opts)
      |> Mappy.set("req.header", req.header)
      |> Mappy.set("req.body", req.body)
      |> Mappy.set("req.peer", req.peer)
      |> Mappy.set("req.remote_ip", req.remote_ip)
      |> Mappy.merge(req.vars)
    %{state | mappy: map, args: req.args, opts: req.opts}
  end

  defp play! state = %State{req: req, app: app, mod: mod} do
    fun = App.real_fun(app, req.fun) || App.real_fun(app, App.default_fun)
      #|| raise Error.FunctionNotFound, state: %{state | fun: req.fun}
    apply(mod, fun, [state])
  end

  defp reply! %{mappy: map, req: req} do
    result_data = Mappy.val(map, "data")
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

  def terminate(_reason, _state) do
    #Dex.JS.return_handle state.js
    :ok
  end

end

