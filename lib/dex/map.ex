defmodule Dex.Map do

  use Dex.Common

  @regex_keysplit ~r/^[^\.:]+|\.{1}[^\.:]+|:{1}[-\w]+/

  defmacro __using__(opts) do
    quote do
      alias unquote(__MODULE__), unquote(opts)
    end
  end # defmacro

  def set(map, key, val) when is_bitstring(key) do
    case parse_var! key do
      "" -> nil
      [{:val, key} | rest] ->
        Map.put map, key, do_set(map[key], rest, val, map)
    end
  end

  defp do_set(_parent, [], val, _map) do val end

  defp do_set(parent, [{:val, key} | rest], val, map) do
    parent2 = BIF.get(parent, key)
    Map.put parent || %{}, key, do_set(parent2, rest, val, map)
  end

  defp do_set(parent, [{:list, [var: key]} | rest], val, map) do
    key = map[key]
    parent2 = BIF.get(parent, key)
    Map.put parent || %{}, key, do_set(parent2, rest, val, map)
  end

  defp do_set(parent, [{:list, [val: key]} | rest], val, map) do
    parent2 = BIF.get(parent, key)
    Map.put parent || %{}, key, do_set(parent2, rest, val, map)
  end

  defp do_set(nil, [{:list, [number: no]} | rest], val, map) do
    (no in ["0", "_"]) && [do_set(nil, rest, val, map)] || nil
  end

  defp do_set(parent, [{:list, [number: "_"]} | rest], val, map) when is_list(parent)  do
    List.insert_at parent, length(parent), do_set(nil, rest, val, map)
  end

  defp do_set(parent, [{:list, [number: no]} | rest], val, map) when is_list(parent)  do
    new_parent = Enum.at parent, no
    List.replace_at parent, no, do_set(new_parent, rest, val, map)
  end

  def val(map, key) when is_list(key) do
    val_parsed key, map, map
  end

  def val(map, key) when is_bitstring(key) do
    val(map, parse_var! key)
  end

  defp val_parsed([], parent, _map) do parent end

  defp val_parsed([{:var, var} | rest], parent, map) do
    if val = map[var], do: (val_parsed rest, BIF.get(parent, val), map),
    else: (val_parsed rest, nil, map)
  end

  defp val_parsed([{:val, val} | rest], parent, map) do
    val_parsed rest, BIF.get(parent, val), map
  end

  defp val_parsed([{:number, val} | rest], parent, map) do
    val_parsed rest, BIF.at(parent, val), map
  end

  defp val_parsed([{:range, {a, b}} | rest], parent, map) do
    val_parsed rest, BIF.slice(parent, a..b), map
  end

  defp val_parsed([{:list, list} | rest], parent, map) do
    res = if length(list) > 1,
      do: Enum.map(list, &(val_parsed [&1], parent, map)) |> List.flatten,
      else: val_parsed(list, parent, map)
    val_parsed rest, res, map
  end

  defp val_parsed([{:multiple, val} | rest], parent, map) do
    val2 = val_parsed val, map, map
    parent2 = BIF.get(parent, val2)
    val_parsed rest, parent2, map
  end

  def transform_bracket str do
    str
      |> String.replace(~r/\s+/, "")
      |> String.replace(~r/^,+$/, "0,,-1")
      |> do_transform_bracket
  end

  defp do_transform_bracket "" do "" end
  defp do_transform_bracket "_" do ":_" end

  defp do_transform_bracket str do
    res = str
      |> do_transform_bracket(:preprocess)
      |> do_transform_bracket(:ranges)
      |> do_transform_bracket(:numbers)
      |> do_transform_bracket(:strings)
      |> do_transform_bracket(:multiple)
      |> do_transform_bracket(:postprocess)
    ":" <> res
  end

  defp do_transform_bracket str, :preprocess do
    str
      |> String.replace(~r/\s+/, "")
      |> String.replace(~r/,,+-?[0-9]+,,+/u, ",,")
      |> String.replace(~r/(\.|:)+/, "\\1")
  end

  defp do_transform_bracket str, :ranges do
    str
      |> String.replace(~r/(-?[0-9]+),,(-?[0-9]+)(?=,|$)/u, ":r\\1_\\2")
      |> String.replace(~r/^,+(-?[0-9]+)/u, ":r0_\\1")
      |> String.replace(~r/(-?[0-9]+),+$/u, ":r\\1_-1")
  end

  defp do_transform_bracket str, :numbers do
    str
      |> String.replace(~r/(?<=^|,)(-?[0-9]+)(?=,|$)/u, ":n\\1")
  end

  defp do_transform_bracket str, :strings do
    str
      |> String.replace(~r/(?<=^|,)"([-\w]+)"(?=,|$)/u, ":q\\1")
      |> String.replace(~r/(?<=^|,)([-\w]+)(?=,|$)/u, ":s\\1")
  end

  defp do_transform_bracket str, :multiple do
    ~r/(?<=^|,)([-\w]+[.:][.:-\w]+)(?=,|$)/u
      |> Regex.replace(str, fn _, f1 ->
        res = f1
          |> String.replace(".", "__1__")
          |> String.replace(":", "__2__")
        ":m" <> res
      end)
  end

  defp do_transform_bracket str, :postprocess do
    str
      |> String.trim(",")
      |> String.replace(~r/:([a-z])/, "\\1")
      |> String.replace(~r/,/, "--")
  end

  def parse_var! str do
    ~r/^[^\.:]+|\.{1}[^\.:]+|:{1}[-\w]+/u
      |> Regex.scan(str) |> List.flatten
      |> do_parse_var!([])
  end

  defp do_parse_var! [], acc do
    acc |> Enum.reverse
  end

  defp do_parse_var! ["." <> val | rest], acc do
    do_parse_var! rest, [{:val, val} | acc]
  end

  defp do_parse_var! [":" <> val | rest], acc do
    res = String.split(val, ~r/--(?=[_a-z])/u)
      |> Enum.map(fn 
        "_" <> _   -> {:number, "_"}
        "n" <> val -> {:number, String.to_integer val}
        "r" <> val -> {:range, split_range(val, "_")}
        "s" <> val -> {:var, val}
        "q" <> val -> {:val, val}
        "m" <> val -> {:multiple, parse_multiple val}
        _ -> {:number, String.to_integer val}
      end)
    do_parse_var! rest, [{:list, res} | acc]
  end

  defp do_parse_var! [val | rest], acc do
    do_parse_var! rest, [{:val, val} | acc]
  end

  defp split_range str, delimiter do
    [a, b] = String.split(str, delimiter, parts: 2)
    {String.to_integer(a), String.to_integer(b)}
  end

  defp parse_multiple val do
    val
      |> String.replace("__1__", ".")
      |> String.replace("__2__", ":")
      |> parse_var!
  end

  def exist?(map, key) do
    case Regex.scan(@regex_keysplit, key) do
      [] -> false
      [[^key]] -> Map.has_key?(map, key)
      split ->
        [[last_key] | tail] = Enum.reverse(split)
        if item = val(map, Enum.join(tail)) do
          case last_key do
            "." <> key -> Map.has_key? item, key
            ":" <> no -> length(item) > String.to_integer(no)
          end
        else
          false
        end
    end
  end

  def fast_transform_bracket "" do "" end

  def fast_transform_bracket str do
    with \
      false <- Regex.match?(~r/^,+$/, str) && :all,
      false <- Regex.match?(~r/(^|,)-?[0-9]+(,|$)/u, str) && :numbers,
      false <- Regex.match?(~r/^,+-?[0-9]+|-?[0-9]+,+|-?[0-9]+,,+-[0-9]+$/u, str) && :ranges,
      false <- Regex.match?(~r/^("?)[\w-]+\1,?/u, str) && :strings,
      false <- Regex.match?(~r/(^|,)[-\w]+[.:][.:-\w]+(,|$)/u, str) && :multiple
    do str else
      :all -> ""
      type -> res = str
        |> do_transform_bracket(:preprocess)
        |> do_transform_bracket(type)
        |> do_transform_bracket(:postprocess)
        ":" <> res
    end
  end

  def unset(map, key) do
    if exist?(map, key) do
      case Regex.scan(@regex_keysplit, key) do
        [] -> map
        [[^key]] -> Map.delete map, key
        [[head] | tail] ->
          Map.put map, head, do_unset(map[head], tail)
      end
    else
      map
    end
  end

  defp do_unset(val, [["." <> key] | tail]) when is_map(val) do
    if tail == [] do
      Map.delete val, key
    else
      Map.put val, key, do_unset(val[key], tail)
    end
  end

  defp do_unset(val, [[":" <> no] | tail]) when is_list(val) do
    no = String.to_integer(no)
    if tail == [] do
      List.delete_at val, no
    else
      List.replace_at val, no, do_unset(Enum.at(val, no), tail)
    end
  end

  def count(map, key) do
    (cnt = val map, key) && Enum.count(cnt) || 0
  end

  def keys(map) when is_map(map) do
    Map.keys map
  end
  
  def keys(_) do
    []
  end

  def keys(map, key) do
    val(map, key) |> keys
  end

  def merge(map1, map2) when is_map(map1) and is_map(map2) do
    Map.merge map1, map2
  end

end

