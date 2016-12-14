defmodule Dex.KV do

  use Dex.Common

  @adapter Application.get_env(:dex, __MODULE__)[:adapter]

  @type error :: {:error, reason}
  @type reason :: term

  @callback start_link(list, pos_integer) :: {:ok, pid} | error
  defdelegate start_link, to: @adapter
  defdelegate start_link(host, port), to: @adapter

  @callback put(binary, binary, binary, list(Keyword.t)) :: :ok | error
  defdelegate put(bucket, key, val, opts \\ []), to: @adapter

  @callback get(binary, binary) :: {:ok, term} | error
  defdelegate get(bucket, key), to: @adapter

  @callback del(binary, binary) :: :ok | error
  defdelegate del(bucket, key), to: @adapter

  def unique_key do
    Lib.now(:usecs) |> to_string
  end

end
