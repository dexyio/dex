defmodule Dex.Service.Seater do

  use GenServer
  use Dex.Common
  alias Dex.Cache
  alias Dex.Service.App
  require Logger

  defmodule Seat do
    defstruct no: nil,
              ttl: nil,
              allocated: nil

    @type t :: %__MODULE__{
      no: non_neg_integer,
      ttl: non_neg_integer,
      allocated: non_neg_integer
    }
  end

  defmodule State do
    defstruct free_seats: [],
              used_seats: [] 
  end

  @seater __MODULE__
  @bucket :seater

  defmacro predef_module_name, do: "DEX.APPS"

  _="""
  def start_new child_id \\ __MODULE__, opts \\ [] do
    start_child(:worker, __MODULE__, [opts], id: child_id)
  end
  """
  @spec take_app(bitstring, bitstring) :: {:ok, {%App{}, module}} | {:error, term}

  def take_app user_id, app_id do
    with \
      nil               <- cached_app(user_id, app_id),
      {:ok, app}        <- App.get(user_id, app_id),
      :ok               <- check_app(app),
      {:ok, module}     <- alloc_app(app)
    do
      {:ok, {app, module}}
    else
      {:error, _reason} = err -> err
      cached_app -> {:ok, cached_app}
    end
  end

  defp cached_app user_id, app_id do
    Cache.get @bucket, {user_id, app_id || ""}
  end

  @spec alloc_app(%App{}) :: {:ok, module} | {:error, term}

  def alloc_app app do
    with \
      {:ok, no}         <- take_seat(),
      {:ok, module}     <- compile_app(app, no),
      :ok               <- put_app(app, module)
    do
      Logger.debug "allocated_seat=#{no}"
      {:ok, module}
    else
      {:error, _reason} = err -> err
    end
  end

  @spec take_seat() :: {:ok, pos_integer} | {:error, term}

  def take_seat do
    GenServer.call @seater, :take_seat
  end

  defp do_take_seat state = %State{free_seats: [no | rest]} do
    new_seat = %Seat{no: no}
    used = [new_seat | state.used_seats]
    state = %{state | free_seats: rest, used_seats: used}
    {state, {:ok, no}}
  end

  defp do_take_seat state = %State{free_seats: []} do
    {state, {:error, :no_seats}}
  end

  @spec free_seats() :: list

  def free_seats do
    GenServer.call __MODULE__, :free_seats
  end

  defp do_free_seats %State{free_seats: free_seats} do
    free_seats |> length
  end

  @spec used_seats() :: list

  def used_seats do
    GenServer.call __MODULE__, :used_seats
  end

  defp do_used_seats %State{used_seats: used_seats} do
    used_seats |> length
  end

  def total_seats do
    conf()[:total_seats]
  end

  defp check_app app do
    app.enabled && :ok || {:error, :app_disabled}
  end

  defp compile_app app, seat_no do
    module = module_name seat_no
    {mod, _bin} = App.compile! app, module
    {:ok, mod}
  end

  defp module_name seat_no do
    "#{predef_module_name()}#{seat_no}" |> String.to_existing_atom
  end

  defp put_app app, module do
    Cache.put @bucket, {app.owner, app.id}, {app, module}
  end

  defp reserve_module_names do
    1..conf()[:total_seats]
      |> Enum.each(& String.to_atom "#{predef_module_name()}#{&1}")
  end

  defp init_cache _state do
    {:ok, _pid} = Cache.new_bucket @bucket; :ok
  end

  defp init_seats state do
    max = conf()[:total_seats]
    seats = (1..max) |> Enum.to_list
    {:ok, %{state | free_seats: seats}}
  end

  def leave_seat state = %State{free_seats: free_seats}, no do
    Enum.member?(free_seats, no) \
      && {:error, :seat_already_exists} \
      || {:ok, %{state | free_seats: [no | free_seats]}}
  end

  ## callback functions

  def start_link opts \\ [] do
    with state = %State{},
      :ok <- reserve_module_names(),
      :ok <- init_cache(state),
      {:ok, state} <- init_seats(state)
    do
      GenServer.start_link(__MODULE__, state, opts)
    end
  end

  def handle_call :free_seats, _from, state do
    res = do_free_seats state
    {:reply, res, state}
  end

  def handle_call :used_seats, _from, state do
    res = do_used_seats state
    {:reply, res, state}
  end

  def handle_call :take_seat, _from, state do
    {state, res} = do_take_seat state
    {:reply,  res, state}
  end

  def handle_call _, _, state do
    {:reply, nil, state}
  end

  def handle_info _, state do
    {:noreply, state}
  end

end
