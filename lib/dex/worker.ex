defmodule Dex.Worker do

  use GenServer
  use Dex.Common
  use Dex.Helper
  alias DexyLib.Mappy
  alias Dex.User
  alias Dex.App
  alias Dex.Request
  require Dex.Code
  require Logger

  alias Dex.Service.State

  @spec start_link(Proplists.t) :: {:ok, pid} | {:error, term}

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, new_state(), args)
  end

  @spec new_state() :: %Dex.Service.State{}

  def new_state do
    %State{
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

  defp do_play state = %{req: req} do
    try do
      case req.fun do
        "_" <> _ = fun -> state |> auth_basic! |> play_bif!(fun)
        _ -> state |> take_app! |> check! |> play_app!
      end
    rescue
      ex in Error.Stopped -> reply! ex.state
      ex -> ex |> inspect_exception(state) |> reply_error!(state.req)
    end
  end

  defp play_bif! state = %State{}, "_test" do
    state |> alloc_temporary_app! |> play_app!
  end

  defp play_bif! state = %State{}, "_deploy" do
    state |> deploy_app! 
  end

  defp play_bif! state = %State{req: req}, "_script" do
    case App.get(req.user, req.app) do
      {:ok, app} -> reply! app.script, state
      {:error, reason} -> raise Error.AppNotFound, state: state,
        reason: Lib.to_string(reason)
    end
  end

  defp play_bif! state = %State{req: req}, "_enable" do
    case App.enable(req.user, req.app) do
      :ok -> reply! "ok", state
      {:error, reason} -> raise Error.AppEnableFailed, state: state,
        reason: Lib.to_string(reason)
    end
  end

  defp play_bif! state = %State{req: req}, "_disable" do
    case App.disable(req.user, req.app) do
      :ok -> reply! "ok", state
      {:error, reason} -> raise Error.AppDisableFailed, state: state,
        reason: Lib.to_string(reason)
    end
  end

  defp play_bif! state = %State{req: req}, "_delete" do
    with \
      {:ok, app} <- App.get(req.user, req.app),
      false <- app.enabled && :app_not_disabled,
      :ok <- App.delete(req.user, req.app)
    do reply! "ok", state else
      :app_not_disabled -> raise Error.AppNotDisabled, state: state
      {:error, reason} -> raise Error.AppDeletionFailed, state: state,
        reason: Lib.to_string(reason)
    end
  end

  defp inspect_exception ex, state do  
    #IO.inspect ex;
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
  end

  defp deploy_app! state = %{user: user, req: req}  do
    case App.put(user.id, req.app, req.body) do
      :ok -> reply! "ok", state
      {:error, reason} -> raise Error.AppDeploymentFailed, state: state,
        reason: Lib.to_string(reason)
    end
  end

  defp alloc_temporary_app! state = %{user: user, req: req} do
    app = App.parse!(user.id, req.body)
    case App.Pool.alloc_temporary app do
      {:ok, module, _no} -> %{state | app: app, mod: module}
      {:error, reason} -> raise Error.AppAllocationFailed, state: state,
        reason: Lib.to_string(reason)
    end
  end

  defp play_app! state = %State{} do
    state |> init! |> play! |> reply!
  end

  defp take_app! state = %State{req: req} do
    {user_id, app_id} = split_user_app state
    case App.Pool.take user_id, app_id do
      {app, module, _no} -> %{state | app: app, mod: module}
      {:error, :app_notfound} -> raise Error.AppNotFound,
        code: Code.not_found, reason: req.app, state: state
      {:error, reason} -> raise Error.AppLoadingFailed,
        reason: reason, state: state
    end
  end

  defp split_user_app %State{req: req} do
    case req.app do
      app_id = "_" <> _ -> {"*", app_id}
      app_id -> {req.user, app_id || ""}
    end
  end
 
  defp check! state = %State{req: req, app: app} do
    case app.funs[req.fun] do
      nil -> state
      %{access: :public} -> state
      %{access: :protected} -> auth_basic! state
      _private -> raise Error.FunctionNotFound, state: %{state | fun: req.fun}
    end
  end
  
  defp init! state = %State{req: req} do
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
    fun = App.real_fun(req.fun, app) 
      || raise Error.FunctionNotFound, state: %{state | fun: req.fun}
    apply(mod, fun, [state])
  end

  defp reply! %{mappy: map, req: req} do
    result_data = Mappy.val(map, "data")
    send req.callback, {req.id, {:ok, result_data}}
  end

  defp reply! data, %{req: req} do
    send req.callback, {req.id, {:ok, data}}
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

