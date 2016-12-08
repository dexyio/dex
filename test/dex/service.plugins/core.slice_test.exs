defmodule Dex.Service.Plugins.Core.SliceTest do

  use ExUnit.Case, async: false
  use Dex.Test

  setup do
    :ok
  end

  test "range" do
    ~S"""
      <data>
        | set 1..10 | slice 0, 3 | assert [1, 2, 3]
        | set 1..10 | slice 0..2 | assert [1, 2, 3]
        | slice 1..10, 0, 3 | assert [1, 2, 3]
        | slice 1..10, 0..2 | assert [1, 2, 3]
        | nil
      </data>
    """ |> assert!(nil)
  end

  test "list" do
    ~S"""
      <data>
        | set [1, 2, 3] | slice 0, 3 | assert [1, 2, 3]
        | set [1, 2, 3] | slice 0..2 | assert [1, 2, 3]
        | set [1, 2, 3] | slice 0..-1 | assert [1, 2, 3]
        | set [1, 2, 3] | slice 1..-1 | assert [2, 3]
        | set [1, 2, 3] | slice -1, 1 | assert [3]
        | slice [1, 2, 3], 0, 3 | assert [1, 2, 3]
        | slice [1, 2, 3], 3, 1 | assert []
        | slice [1, 2, 3], 0..2 | assert [1, 2, 3]
        | slice [1, 2, 3], 10..1 | assert []
        | nil
      </data>
    """ |> assert!(nil)
  end

  test "map" do
    ~S"""
      <data>
        | set {a: 1, b: 2, c: 3} | slice 0, 2 | assert {a: 1, b: 2}
        | slice 0..1 | assert {a: 1, b: 2}
        | slice 0, 1 | assert {a: 1}
        | nil
      </data>
    """ |> assert!(nil)
  end

  test "bitstring" do
    ~S"""
      <data>
        | set "hello" | slice 0, 2 | assert "he"
        | set "hello" | slice 0..1 | assert "he"
        | set "hello" | slice -2..-1 | assert "lo"
        | slice "hello", 0, 10 | assert "hello"
        | nil
      </data>
    """ |> assert!(nil)
  end

  test "error" do
    ~S"""
    @dexyml
    | set 1..10 | slice a, b, c, d
    """ |> assert_raise!(Dex.Error.BadArity)
    ~S"""
    @dexyml
    | set 1..10 | slice a, b
    """ |> assert_raise!(Dex.Error.InvalidArgument)
  end  

end
