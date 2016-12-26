defmodule Dex.KV do

  use Dex.Common

  @adapter Application.get_env(:dex, __MODULE__)[:adapter]

  defmodule Adapter do
    @type error :: {:error, reason}
    @type reason :: term

    @callback start_link(list, pos_integer) :: {:ok, pid} | error
    @callback put(binary, binary, binary, list(Keyword.t)) :: :ok | error
    @callback get(binary, binary) :: {:ok, term} | error
    @callback delete(binary, binary) :: :ok | error
  end

  defdelegate start_link, to: @adapter
  defdelegate start_link(host, port), to: @adapter
  defdelegate put(bucket, key, val, opts \\ []), to: @adapter
  defdelegate get(bucket, key), to: @adapter
  defdelegate delete(bucket, key), to: @adapter

  def unique_key do
    Lib.now(:usecs) |> to_string
  end

end
