defmodule Dex.Seater do

  defmodule Supervisor do
    use DexyLib.Supervisor, otp_app: :dex
  end

  defmodule State do
    defstruct name: nil,
              size: 0,
              used: %{},
              free: []

    @type t :: %__MODULE__{
      name: atom,
      size: non_neg_integer,
      used: map,
      free: list
    }
  end

  defmodule Seat do
    defstruct type: nil,
              no: 0,
              data: nil,
              opts: [],
              touched: 0

    @type seater_name :: atom
    @type seat_no :: non_neg_integer
    @type seconds :: non_neg_integer
    @type t :: %__MODULE__{
      type: seater_name,
      no: seat_no,
      data: any,
      #on_purge: nil | (seat_no, any -> true | false),
      opts: Keyword.t,
      touched: seconds
    }
  end

  use Dex.Common
  require Logger

  default_purge_after_msecs = 60_000
  default_ttl_secs = 60

  @ttl_secs Application.get_env(:dex, __MODULE__)[:ttl_secs] || (
    Logger.warn ":ttl_secs not configured, default: #{default_ttl_secs}";
    default_ttl_secs
  )
  @purge_after_msecs Application.get_env(:dex, __MODULE__)[:purge_after_msecs] || (
    Logger.warn ":purge_after_msecs not configured, default: #{default_purge_after_msecs}";
    default_purge_after_msecs
  )

  @spec create(atom, Seat.seat_no) :: :ok | {:error, term}

  def create name, size do
    __MODULE__.Supervisor.start_child \
      :worker, __MODULE__, [{name, size}], [id: name]
  end
  
  @spec stop(pid | atom) :: :ok | {:error, term}

  def stop server do
    Elixir.Supervisor.terminate_child __MODULE__.Supervisor, server
  end

  @spec destroy(pid | atom) :: :ok | {:error, term}

  def destroy server do
    Elixir.Supervisor.delete_child __MODULE__.Supervisor, server
  end

  @spec restart(pid | atom) :: :ok | {:error, term}

  def restart server do
    Elixir.Supervisor.restart_child __MODULE__.Supervisor, server
  end

  @spec members() :: list

  def members do
    __MODULE__.Supervisor.members
  end

  @spec status() :: list

  def status do
    members() |> Enum.map(fn
      {name, :undefined} -> {name, :stoped}
      {name, pid} -> {name, pid: pid, used: used_seats(name), free: free_seats(name)}
    end)
  end

  @spec take(pid | atom, Keyword.t) :: Seat.seat_no | nil

  def take server, opts \\ [] do
    GenServer.call server, {:take, opts}
  end

  defp do_take opts, state = %State{free: [no | rest]} do
    seat = %Seat{type: state.name, no: no, opts: opts, touched: Lib.now :secs}
    used = Map.put state.used, no, seat
    {no, %{state | free: rest, used: used}}
  end

  defp do_take _opts, state = %State{free: []} do
    {nil, state}
  end

  def touch server, seat_no do
    GenServer.call server, {:touch, seat_no}
  end

  defp do_touch seat_no, state = %{used: used} do
    case used[seat_no] do
      nil -> state
      seat ->
        seat = %{seat | touched: Lib.now :secs}
        used = Map.put used, seat_no, seat
        %{state | used: used}
    end
  end

  @spec put(pid | atom, Seat.seat_no, term) :: Seat.seat_no | nil

  def put server, seat_no, data do
    GenServer.call server, {:put, seat_no, data}
  end

  defp do_put seat_no, data, state = %{used: used} do
    case Map.fetch(used, seat_no) do
      :error -> {nil, state}
      {:ok, seat} -> 
        used = Map.put used, seat_no, %{seat | data: data}
        {seat_no, %{state | used: used}}
    end
  end

  @spec take_and_put(pid | atom, any, Keyword.t) :: Seat.seat_no | nil

  def take_and_put server, data, opts \\ [] do
    GenServer.call server, {:take_and_put, data, opts}
  end

  def do_take_and_put data, opts, state do
    case do_take opts, state do
      {nil, _state} -> {nil, state}
      {no, state} -> do_put no, data, state
    end
  end

  @spec return(pid | atom, Seat.seat_no) :: :ok

  def return server, no do
    GenServer.call server, {:return, no}
  end

  defp do_return no, state = %{used: used, free: free} do
    state = %{state | used: Map.delete(used, no), free: [no | free]}
    {:ok, state}
  end

  @spec get(pid | atom, Seat.seat_no) :: term

  def get server, no do
    GenServer.call server, {:get, no}
  end

  defp do_get no, state = %{used: used} do
    {Map.get(used, no), state}
  end

  @spec free_seats() :: Keyword.t

  def free_seats do
    __MODULE__.Supervisor.members() |> Enum.map(fn
      {name, :undefined} -> {name, :stoped}
      {name, _pid} -> {name, GenServer.call(name, :free_seats)}
    end)
  end

  @spec free_seats(pid | atom) :: list

  def free_seats server do
    GenServer.call server, :free_seats
  end

  defp do_free_seats state = %State{free: free} do
    {free |> Enum.count, state}
  end

  @spec used_seats() :: Keyword.t

  def used_seats do
    __MODULE__.Supervisor.members() |> Enum.map(fn 
      {name, :undefined} -> {name, :stoped}
      {name, _pid} -> {name, GenServer.call(name, :used_seats)}
    end)
  end

  @spec used_seats(pid | atom) :: list

  def used_seats server do
    GenServer.call server, :used_seats
  end

  defp do_used_seats state = %State{used: used} do
    {used |> Enum.count, state}
  end

  defp reserve_purge server do
    Process.send_after server, :reserve_purge, @purge_after_msecs
  end

  defp purge_seats state = %State{used: used, free: free} do
    now = Lib.now :secs
    acc = {[], free}
    {used, free} = Map.values(used) |> do_purge_seats(now, acc)
    Logger.debug "#{state.name}=#{inspect used: Enum.count(used), free: length(free)}"
    %{state | used: used, free: free}
  end

  defp do_purge_seats [], _now, {used, free} do
    {used |> Enum.into(%{}), free}
  end

  defp do_purge_seats [seat | rest], now, {used, free} do
    %Seat{no: no, touched: touched, opts: opts} = seat
    ttl = opts[:ttl_secs] || @ttl_secs
    on_purge = opts[:on_purge]
    acc = with \
      true <- (now - touched) >= ttl || :not_expired,
      true <- (on_purge == nil or (on_purge && on_purge.(seat) && true)) || :no_purge
    do {used, [no | free]} else
      _ -> {[{no, seat} | used], free}
    end
    do_purge_seats rest, now, acc
  end

  # Callbacks

  def start_link arg = {name, _size} do
    GenServer.start_link __MODULE__, arg, name: name
  end

  def init {name, size} do
    state = %State{
      name: name,
      size: size,
      free: 1..size |> Enum.to_list
    }
    reserve_purge name
    {:ok, state}
  end

  def handle_call {:take, opts}, _from, state do
    {res, state} = do_take opts, state
    {:reply, res, state}
  end

  def handle_call {:touch, seat_no}, _from, state do
    state = do_touch seat_no, state
    {:reply, :ok, state}
  end

  def handle_call {:put, seat_no, data}, _from, state do
    {res, state} = do_put seat_no, data, state
    {:reply, res, state}
  end

  def handle_call {:take_and_put, data, opts}, _from, state do
    {res, state} = do_take_and_put data, opts, state
    {:reply, res, state}
  end

  def handle_call {:return, no}, _from, state do
    {res, state} = do_return no, state
    {:reply, res, state}
  end

  def handle_call {:get, no}, _from, state do
    {res, state} = do_get no, state
    {:reply, res, state}
  end

  def handle_call :free_seats, _from, state do
    {res, state} = do_free_seats state
    {:reply, res, state}
  end

  def handle_call :used_seats, _from, state do
    {res, state} = do_used_seats state
    {:reply, res, state}
  end

  def handle_info :reserve_purge, state do
    state = purge_seats state
    reserve_purge state.name
    {:noreply, state}
  end

  def terminate _reason, _state do
    :ok
  end

end
