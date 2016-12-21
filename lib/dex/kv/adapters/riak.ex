defmodule Dex.KV.Adapters.Riak do

  use Timex
  use Dex.Common
  alias DexyLib.JSON

  @behaviour Dex.KV.Adapter
  @default_content_type "application/x-erlang-binary"

  def start_link(host \\ '127.0.0.1', port \\ 8087) do
    :riakc_pb_socket.start_link(host, port)
  end

  def init_search do
    create_search_schemes
    create_search_indices
    create_bucket_types
    activate_bucket_types
    check_all_conf
    IO.puts ~S"""

    == YOU MUST APPLY CUSTOM EXTRACTORS FOR RIAK SEARCH ==
      
      $ riak attach
      > yz_extractor:register("YOUR_CONTENT_TYPE", YOUR_CUSTOM_EXTRACTOR).
      > yz_extractor:run(term_to_binary([]), YOUR_CUSTOM_EXTRACTOR).

    """
  end

  def check_all_conf do
    IO.puts "check_search_schemes: #{inspect check_search_schemes}"
    IO.puts "check_search_indices: #{inspect check_search_indices}"
    IO.puts "check_bucket_types: #{inspect check_bucket_types}"
  end

  def check_search_schemes do
    for {schema, props} <- conf_search_schemes do
      xml = File.read! props[:file]
      case get_search_schema(schema) do
        {:ok, ^xml} -> {schema, :ok}
        error -> {schema, error}
      end
    end
  end

  def check_search_indices() do
    for {index, props} <- conf_search_indices do
      res = case get_search_index(index) do
        {:ok, props2} ->
          same_props?(props, props2, :schema) ||
            {:error, "schema(#{props2[:schema]}) not matched."} &&
          same_props?(props, props2, :n_val, 3) ||
            {:error, "n_val(#{props2[:n_val]}) not matched."} &&
          :ok
        error ->
          error
      end
      {index, res}
    end
  end

  def show_bucket_types do
    os_cmd("riak-admin bucket-type list")
  end

  def create_bucket_types do
    for {type, props} <- conf_bucket_types do
      create_bucket_type(type, props)
    end
  end

  def update_bucket_types do
    for {type, props} <- conf_bucket_types do
      update_bucket_type(type, props)
    end
  end

  def create_bucket_type(type, props) do
    json = JSON.encode! %{
      props: props |> Enum.into(%{})
    }
    (cmd = "riak-admin bucket-type create #{type} '#{json}'"
      |> String.to_char_list)
      |> os_cmd
    {type, cmd}
  end

  def update_bucket_type(type, props) do
    json = JSON.encode! %{props: props |> Enum.into(%{})}
    (cmd = "riak-admin bucket-type update #{type} '#{json}'"
      |> String.to_char_list)
      |> os_cmd
    {type, cmd}
  end

  def activate_bucket_types do
    for {type, _} <- conf_bucket_types do
      activate_bucket_type(type)
    end
  end

  def activate_bucket_type(type) do
    cmd = "riak-admin bucket-type activate #{type}"
      |> os_cmd
    {type, cmd}
  end

  def os_cmd(cmd) when is_bitstring(cmd) do
    os_cmd(cmd |> String.to_char_list)
  end

  def os_cmd(cmd) do
    :os.cmd(cmd) |> IO.puts
  end

  def check_bucket_types() do
    for {type, props} <- conf_bucket_types do
      res = case get_bucket_type(type) do
        {:ok, props2} ->
          for {k, v} <- props do
            props2[k] == v ||
              throw {:error, "bucket type #{type}'s allow_mult(#{props2[k]}) not matched."}
          end
        error ->
          error
      end
      {type, res}
    end
  end

  def same_props?(props, props2, keyword, default \\ nil)
    when is_atom(keyword) and is_list(props) and is_list(props2)
  do
    props[keyword] == (props2[keyword] || default)
  end


  def ping do
    pool &:riakc_pb_socket.ping(&1)
  end

  def get_search_schema(schema) do
    case pool &:riakc_pb_socket.get_search_schema(&1, schema) do
      {:ok, props} -> {:ok, props[:content]}
      error -> error
    end
  end

  def get_search_index(index) do
    pool &:riakc_pb_socket.get_search_index(&1, index)
  end

  def get_bucket_type(type) do
    pool &:riakc_pb_socket.get_bucket_type(&1, type)
  end

  def conf_search_schemes, do: conf[:search_schemes]
  def conf_search_indices, do: conf[:search_indices]
  def conf_bucket_types, do: conf[:bucket_types]

  def create_search_schemes do
    for {schema, props} <- conf_search_schemes do
      xml = File.read! props[:file]
      res = create_search_schema(schema, xml)
      {schema, res}
    end
  end

  def create_search_schema(schema, xml) do
    pool &:riakc_pb_socket.create_search_schema(&1, schema, xml)
  end

  def create_search_indices do
    for {index, props} <- conf_search_indices do
      schema = props[:schema] || throw {:error, "index #{index}'s schema: nil"}
      case get_search_schema(schema) do
        {:ok, _props} -> 
          opts = [n_val: props[:n_val] || 3]
          res = create_search_index(index, schema, opts)
          {index, res}
        error ->
          {index, error}
      end
    end
  end

  def create_deafult_search_index(index) do
    pool &:riakc_pb_socket.create_search_index(&1, index)
  end

  def create_search_index(index, schema, opts) do
    pool &:riakc_pb_socket.create_search_index(&1, index, schema, opts)
  end

  def put(bucket, key, val) do
    put(bucket, key, val, [])
  end

  def put(bucket, key, val, opts) do
    type = opts[:content_type] || @default_content_type
    new_object(bucket, key, Lib.to_binary(val), type)
    |> put_object
  end

  def get(bucket, key) do
    case get_object bucket, key do
      {:ok, obj} -> {:ok, value obj}
      error -> error
    end
  end

  def del(bucket, key) do
    pool &:riakc_pb_socket.delete(&1, bucket, key)
  end

  def search(index, query, opts, timeout) do
    pool &:riakc_pb_socket.search(&1, index, query, opts, timeout)
  end

  def search!(index, query, opts \\ []) do
    search!(index, query, opts, default_timeout(:search))
  end

  def search!(index, query, opts, timeout) do
    case search(index, query, opts, timeout) do
      {:ok, res} -> res
      error -> throw error
    end
  end

  defp put_object(object) do
    pool &:riakc_pb_socket.put(&1, object)
  end

  defp new_object(bucket, key, val, content_type) do
    :riakc_obj.new(bucket, key, val, content_type)
  end

  defp get_object(bucket, key) do
    pool &:riakc_pb_socket.get(&1, bucket, key)
  end

  defp value(object) do
    case :riakc_obj.get_value(object) do
      bin when is_binary(bin) -> Lib.binary_to_term(bin)
      error -> error
    end
  end

  defp default_timeout(:search) do
    :riakc_pb_socket.default_timeout(:search_timeout)
  end

  defp default_timeout(:put) do
    :riakc_pb_socket.default_timeout(:put_timeout)
  end

  defp pool(fun) do
    pid = take_member
    res = fun.(pid)
    return_member pid
    res
  end

  defp take_member, do: :pooler.take_member(Dex.KV)
  defp return_member(pid), do: :pooler.return_member(Dex.KV, pid, :ok)

end

