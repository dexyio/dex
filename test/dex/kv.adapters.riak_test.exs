defmodule Dex.KV.Adapters.RiakTest do

  use ExUnit.Case
  use Dex.Common
  alias Dex.KV.Adapters.Riak

  defmodule DataPut do
    defstruct bucket: nil,
              data: nil,
              created: nil,
              datetime: nil,
              tags: []
  end

  @index_userdata "idx_userdata"
  @bucket_type_userdata "userdata"
  @content_type_userdata 'application/dexyml'

  test "put & get" do
    key = riak_key
    val_ = riak_val
    :ok = Riak.put(riak_bucket, key, val_, content_type: @content_type_userdata)
    {:ok, ^val_} = Riak.get(riak_bucket, key)
  end

  test "search" do
    :ok = Riak.put(riak_bucket, riak_key, riak_val, content_type: @content_type_userdata)
    assert (
      case Riak.search!(@index_userdata, "_yz_rb:#{user} AND bucket:#{bucket}") do
          {:search_results, _, _, cnt} when cnt > 0 -> true
          _ -> false
      end
    ) == true
  end

  def user, do: "kook"
  def bucket, do: "foo"
  def val, do: "bar"

  def object do
  end

  def riak_bucket do
    {@bucket_type_userdata, user} 
  end

  def riak_key do
    bucket <> ":" <> Dex.KV.unique_key
  end

  def riak_val do
    %DataPut{
      bucket: bucket,
      data: val,
      datetime: BIF.datetime_now |> BIF.datetime_format!("isoz"),
      created: BIF.now(:usecs)
    }
    |> Map.from_struct
    |> Map.to_list
  end

end
