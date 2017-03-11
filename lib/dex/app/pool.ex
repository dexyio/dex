defmodule Dex.App.Pool do

  use Dex.Common
  alias Dex.App
  alias Dex.Cache
  alias Dex.Seater
  use GenServer
  require Logger

  @bucket __MODULE__
  @prod :prod
  @test :test

  default_pool_size = 1000
  @pool_size Application.get_env(:dex, __MODULE__)[:pool_size] || (
    Logger.warn ":pool_size not configured, default: #{default_pool_size}";
    default_pool_size
  )

  defmacro app_prefix, do: "DEX.APP"

  def init do
    reserve_app_names()
    create_bucket()
  end

  def take %App{owner: user_id, id: app_id} do
    take user_id, app_id
  end

  def take user_id, app_id do
    key = {@prod, user_id, app_id}
    with \
      nil               <- cached(key),
      {:ok, app}        <- App.get(user_id, app_id),
      true              <- app.enabled || :app_disabled,
      {:ok, module, no} <- new(@prod, app, ttl_secs: 60)
    do {app, module, no} else
      {_app, _mod, no} = res -> Seater.touch @prod, no; res
      error -> error
    end
  end

  def alloc(app), do: new @prod, app, ttl_secs: 60
  def alloc_temporary(app), do: new @test, app, ttl_secs: 10 

  defp new type, app, opts do
    opts = [{:on_purge, &on_purge/1} | opts]
    key = {type, app.owner, app.id}
    with \
      no <- Seater.take_and_put(type, key, opts) || :no_seats,
      {:ok, module} <- compile_app(app, no),
      :ok <- cache(key, {app, module, no})
    do
      Logger.debug inspect(take_seat: type, no: no)
      {:ok, module, no}
    else
      error -> error
    end
  end

  defp cache(key, value), do: Cache.put @bucket, key, value
  defp cached(key), do: Cache.get @bucket, key
  defp uncache(key), do: Cache.del @bucket, key

  defp compile_app app, seat_no do
    module = module_name seat_no
    {mod, _bin} = App.compile! app, module
    {:ok, mod}
  end

  defp module_name seat_no do
    "#{app_prefix()}#{seat_no}" |> String.to_existing_atom
  end

  # Callbacks

  @spec on_app_updated(bitstring, bitstring) :: :ok | {:error, term}

  def on_app_updated user_id, app_id do
    with \
      {_app, _mod, no} <- cached({@prod, user_id, app_id}) || :not_cached,
      {:ok, app} <- App.get(user_id, app_id),
      {:ok, module} <- compile_app(app, no)
    do
      cache({@prod, app.owner, app.id}, {app, module, no})
    else
      :not_cached -> :ok
      error -> Logger.error inspect(on_app_updated: error)
    end
  end

  def on_app_disabled user_id, app_id do
    Logger.debug inspect(on_app_disabled: {user_id, app_id})
    uncache {@prod, user_id, app_id}
  end

  def on_purge %Seater.Seat{no: no, data: key} do
    Logger.debug inspect(on_purge: key, no: no)
    uncache key; :ok
  end

  # Private functions

  defp reserve_app_names do
    1..@pool_size
      |> Enum.each(& String.to_atom "#{app_prefix()}#{&1}")
  end

  def create_bucket do
    {:ok, _pid} = Cache.new_bucket @bucket; :ok
  end

end
