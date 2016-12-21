defmodule Dex.Service.Plugins.JSON do

  use Dex.Common
  use Dex.Service.Helper
  alias DexyLib.JSON

  def encode state = %{opts: opts} do
    res = arg_data(state)
      |> encode_opts(Map.to_list opts)
      |> JSON.encode!
    {state, res}
  end 
  
  def decode state do
    res = JSON.decode! arg_data(state)
    {state, res}
  end

  defp encode_opts(data, opts) do
    Enum.reduce opts, data, fn {key, val}, acc ->
      do_encode_opts({key, val}, acc)
    end
  end

  defp do_encode_opts({"strip", val}, data) when is_map(data) do
    cnt = case val do
      "" -> 1
      n -> Lib.to_number n, 1
    end
    Enum.reduce(1..cnt, data, fn
      (_, acc) when is_map(acc) ->
        case Enum.at acc, 0 do 
          {_key, val} -> val
          nil -> acc
        end
      (_, acc) ->
        acc
    end)
  end

  defp do_encode_opts({"wrap", val}, data) do
    Map.put(%{}, val, data)
  end

  defp do_encode_opts(_, data), do: data

end
