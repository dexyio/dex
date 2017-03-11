defmodule Dex.Plugins.Core.AtTest do

  use ExUnit.Case, async: false
  use Dex.Test

  setup do
    :ok
  end

  test "list" do
    ~S"""
      <data>
        | set [1, 2, 3] | at 0    | assert 1
        | set [1, 2, 3] | at 10   | assert nil
        | set [1, 2, 3] | at -1   | assert 3
        | set [1, 2, 3] | at -10  | assert nil
        | at [1, 2, 3], 0         | assert 1
        | at [1, 2, 3], 10        | assert nil
        | at [1, 2, 3], -1        | assert 3
        | at [1, 2, 3], -10       | assert nil
      </data>
    """ |> assert!(nil)
  end

  test "string" do
    ~S"""
      <data>
        | set foo: "hello"
        | at foo, 0   | assert "h"
        | at foo, -1  | assert "o"
        | at foo, 10  | assert nil
        | at "hello", 0   | assert "h"
        | at "hello", 10  | assert nil
        | at "hello", -1  | assert "o"
        | at "hello", -10 | assert nil
      </data>
    """ |> assert!(nil)
  end

  test "map" do
    ~S"""
      <data>
        | at {a: 1, b: 2}, 0    | assert {"a", 1}
        | at {a: 1, b: 2}, 1    | assert {"b", 2}
        | at {a: 1, b: 2}, -1   | assert {"b", 2}
        | at {a: 1, b: 2}, 10   | assert nil
        | at {a: 1, b: 2}, -10  | assert nil
      </data>
    """ |> assert!(nil)
  end

  test "tuple" do
    ~S"""
      <data>
        | at {1, 2, 3}, 0   | assert 1
        | at {1, 2, 3}, 1   | assert 2
        | at {1, 2, 3}, 10  | assert nil
        | at {1, 2, 3}, -1  | assert 3
        | at {1, 2, 3}, -10 | assert nil
      </data>
    """ |> assert!(nil)
  end

  test "number" do
    ~S"""
      <data>
        | at 10, 0         | assert 0
        | at 10, 10        | assert 10
        | at 10, 100       | assert nil
        | at 10, -1        | assert 10
        | at 10, -100      | assert nil
      </data>
    """ |> assert!(nil)
  end

  test "nil" do
    ~S"""
      <data>
        | at 0        | assert nil
        | at -1       | assert nil
        | at nil, 0   | assert nil
        | at foo, 1   | assert nil
      </data>
    """ |> assert!(nil)
  end

  test "invalid" do
    ~S"""
      <data>
        | at nil      | assert nil
        | at "test"   | assert nil
      </data>
    """ |> assert_raise!(Dex.Error.InvalidArgument)
  end

end

