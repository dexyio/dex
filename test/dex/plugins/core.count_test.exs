defmodule Dex.Plugins.Core.CountTest do

  use ExUnit.Case, async: false
  use Dex.Test

  setup do
    :ok
  end

  test "range" do
    ~S"""
      <data>
        | set 1..10 | count 
      </data>
    """ |> assert!(10)
    ~S"""
      <data>
        | count 1..10
      </data>
    """ |> assert!(10)
  end

  test "list" do
    ~S"""
      <data>
        | set [1, 2, 3] | count 
      </data>
    """ |> assert!(3)
    ~S"""
      <data>
        | count [1, 2, 3]
      </data>
    """ |> assert!(3)
  end

  test "map" do
    ~S"""
      <data>
        | count {a: 1, b: "foo", c: []}
      </data>
    """ |> assert!(3)
  end

  test "tuple" do
    ~S"""
      <data>
        | count {1, 2, 3}
      </data>
    """ |> assert!(3)
  end

  test "string" do
    ~S"""
      <data>
        | count "foo"
      </data>
    """ |> assert!(3)
  end

  test "nil" do
    ~S"""
      <data>
        | count
      </data>
    """ |> assert!(0)
  end

  test "invalid format" do
    ~S"""
      <data>
        | count 123
      </data>
    """ |> assert!(123)
  end
end
