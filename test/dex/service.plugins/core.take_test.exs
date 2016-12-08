defmodule Dex.Service.Plugins.Core.TakeTest do

  use ExUnit.Case, async: false
  use Dex.Test

  setup do
    :ok
  end

  test "range" do
    ~S"""
    @dexyml
    | set 1..5 | take 2
    """ |> assert!([1, 2])
    ~S"""
    @dexyml
    | set 1..5 | take -2
    """ |> assert!([4, 5])
    ~S"""
    @dexyml
    | set 1..5 | take 100
    """ |> assert!([1, 2, 3, 4, 5])
    ~S"""
    @dexyml
    | set 1..5 | take -100
    """ |> assert!([])
  end

  test "list" do
    ~S"""
    @dexyml
    | set 1..5 | to_list | take 2
    """ |> assert!([1, 2])
    ~S"""
    @dexyml
    | set 1..5 | to_list | take -2
    """ |> assert!([4, 5])
    ~S"""
    @dexyml
    | set 1..5 | to_list | take 100
    """ |> assert!([1, 2, 3, 4, 5])
    ~S"""
    @dexyml
    | set 1..5 | to_list | take -100
    """ |> assert!([])
  end

  test "map" do
    ~S"""
    @dexyml
    | set {a:1, b:2, c: 3} | take 1
    """ |> assert!(%{"a" => 1})
    ~S"""
    @dexyml
    | set {a:1, b:2, c: 3} | take -1
    """ |> assert!(%{"c" => 3})
  end

end
