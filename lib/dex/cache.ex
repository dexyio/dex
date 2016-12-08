defmodule Dex.Cache do

  use Behaviour

  @adapter Application.get_env(:dex, __MODULE__)[:adapter]

  @type error :: {:error, reason}
  @type reason :: term

  defcallback new_bucket(atom) :: {:ok, pid} | error
  defdelegate new_bucket(bucket), to: @adapter

  defcallback add(atom, any, any) :: :ok | error
  defdelegate add(bucket, key, val), to: @adapter

  defcallback put(atom, any, any) :: :ok | error
  defdelegate put(bucket, key, val), to: @adapter

  defcallback get(atom, any, any) :: term | error
  defdelegate get(bucket, key), to: @adapter
  defdelegate get(bucket, key, default), to: @adapter

  defcallback del(atom, any) :: :ok | error
  defdelegate del(bucket, key), to: @adapter

  defcallback buckets :: list
  defdelegate buckets, to: @adapter

end
