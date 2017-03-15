defmodule Dex.Service do

  use Dex.Common
  alias Dex.User
  alias Dex.App
  alias Dex.Request
  alias Dex.Worker
  alias DexyLib.Mappy

  defmodule State do
    defmodule Trace do
      defstruct fun: nil, args: [], opts: %{}, line: 0
      @type t :: %__MODULE__{
        fun: bitstring, args: list, opts: map, line: bitstring 
      }
    end

    defstruct req: nil,
              user: nil,
              app: nil,
              mod: nil,
              authorized: false,
              mappy: Mappy.new,
              js: nil,
              fun: nil,
              args: [],
              opts: %{},
              line: 0,
              depth: 0

    @type t :: %__MODULE__{
      req: %Request{},
      user: %User{},
      app: %App{},
      mod: atom,
      authorized: boolean,
      mappy: Mappy.t,
      js: any,
      fun: bitstring,
      args: list,
      opts: map,
      line: bitstring,
      depth: 0 | pos_integer
    }
  end

  defmacro __using__(_) do
    quote do
    end
  end # defmacro

  @type response :: {:ok | :error | :notify, term} 


  @spec start_worker(%User{}, Proplist.t) :: response
  @spec start_worker(%User{}, %Request{}) :: response

  def start_worker(user, req) when is_list(req) do
    start_worker user, struct(Request, req)
  end

  def start_worker user, req = %Request{id: nil} do
    start_worker user, %{req | id: Lib.unique}
  end

  def start_worker user = %User{}, req = %Request{id: rid} do
    {:ok, pid} = Worker.start_link
    res = Worker.play pid, user, req
    {res, rid: rid, pid: pid}
  end

  @default_user "*"

  @spec route(Proplist.t) :: response
  @spec route(%Request{}) :: response

  def route(req) when is_list(req) do struct(Request, req) |> route end
  def route req = %Request{id: nil} do route %{req | id: Lib.unique} end
  def route req = %Request{user: ""} do route %{req | user: @default_user} end
  def route req = %Request{user: user, app: app} do
    do_route {user, app}, req
  end

  def ping do
    do_route {nil, Lib.now :usecs}, :ping
  end

  def do_route path = {_bucket, _key}, req, nodes \\ 1 do
    doc_idx = :riak_core_util.chash_key path
    pref_list = :riak_core_apl.get_primary_apl doc_idx, nodes, Dex.Service
    [{index_node, _type}] = pref_list
    
    # riak core appends "_master" to Dex.Vnode
    :riak_core_vnode_master.sync_spawn_command \
      index_node, req, Dex.Vnode_master
  end

end
