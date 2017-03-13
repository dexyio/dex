defmodule Dex.Cache do

  defmodule Supervisor do
    use DexyLib.Supervisor, otp_app: :dex
  end

  @adapter Application.get_env(:dex, __MODULE__)[:adapter]

  defmodule Adapter do
    @type error :: {:error, reason}
    @type reason :: term

    @callback new_bucket(atom) :: {:ok, pid} | error
    @callback buckets :: list

    @callback add(atom, any, any) :: :ok | error
    @callback put(atom, any, any) :: :ok | error
    @callback get(atom, any, any) :: term | error
    @callback del(atom, any) :: :ok | error
  end

  defdelegate new_bucket(bucket), to: @adapter
  defdelegate buckets, to: @adapter

  defdelegate add(bucket, key, val), to: @adapter
  defdelegate put(bucket, key, val), to: @adapter
  defdelegate get(bucket, key, default \\ nil), to: @adapter
  defdelegate del(bucket, key), to: @adapter

end
