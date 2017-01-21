defmodule Dex.Service.Bot do

  defmodule Supervisor do
    use DexyLib.Supervisor, otp_app: :dex
  end

  defmodule State do
    defstruct name: nil,
              user: nil
  end

  use GenServer
  use Dex.Common
  alias Dex.Service.Worker

  # Interfaces

  @spec new(Proplists.t) :: {:ok, pid} | {:error, term}

  def new user do
    Supervisor.start_child(:worker, __MODULE__, [[user: user]], id: user.id)
  end

  def start_link args do
    GenServer.start_link(__MODULE__, args)
  end

  def request pid, request do
    GenServer.call pid, {:request, request}
  end

  # Server (callbacks)

  def init args do
    user = args[:user]
    true = :gproc.add_local_name user.id
    {:ok, %State{user: user}}
  end

  def handle_call(:ping, _from, state) do
    {:reply, :pong, state}
  end

  def handle_call {:request, req}, _from, state do
    {:ok, pid} = Worker.start_link
    res = Worker.play pid, state.user, req
    res = {res, rid: req.id, pid: pid}
    {:reply, res, state}
  end

  def handle_cast(:data, state) do
    {:noreply, state.data}
  end

end
