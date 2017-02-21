defmodule Dex.Service.Bot do

  defmodule Supervisor do
    use DexyLib.Supervisor, otp_app: :dex
  end

  defmodule State do
    defstruct user: nil

    @type t :: %__MODULE__{
      user: %Dex.Service.User{}
    }
  end

  use GenServer
  use Dex.Common
  alias Dex.Service.Worker
  alias Dex.Service.User
  require Logger

  # Interfaces

  @spec new(Proplists.t) :: {:ok, pid} | {:error, term}

  def new user do
    Supervisor.start_child(:worker, __MODULE__, [[user: user]], id: user.id)
  end

  def find user_id do
    case :gproc.lookup_local_name(user_id) do
      :undefined -> nil
      pid -> pid
    end
  end

  def start_link args do
    GenServer.start_link(__MODULE__, args)
  end

  def request pid, request do
    GenServer.call pid, {:request, request}
  end

  def reload_user user_id do
    case :gproc.lookup_local_name(user_id) do
      :undefined -> {:error, :app_notfound}
      pid -> GenServer.cast pid, :reload_user
    end
  end

  # Server (callbacks)

  def init args do
    user = args[:user]
    true = :gproc.add_local_name user.id
    {:ok, %State{user: user}}
  end

  def handle_call :ping, _from, state do
    {:reply, :pong, state}
  end

  def handle_call {:request, req}, _from, state do
    {:ok, pid} = Worker.start_link
    res = Worker.play pid, state.user, req
    res = {res, rid: req.id, pid: pid}
    {:reply, res, state}
  end

  def handle_cast :reload_user, state = %{user: user} do
    state = case User.get user.id do
      {:ok, user} -> %{state | user: user}
      {:error, reason} ->
        Logger.error "reload_user: #{inspect reason}"
        state
    end
    {:noreply, state}
  end

  def handle_cast(:data, state) do
    {:noreply, state.data}
  end

end
