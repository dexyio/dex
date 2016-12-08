defmodule Dex.Service.Plugins.Core.LengthTest do

  use ExUnit.Case, async: false
  use Dex.Test

  setup do
    :ok
  end

  test "list" do
    ~S"""
      <data>
        | set [1, 2, 3] | length    | assert 3
        | length [1, 2, 3]          | assert 3
        | length []                 | assert 0
      </data>
    """ |> assert!(0)
  end

  test "map" do
    ~S"""
      <data>
        | set {a: 1, b: 2, c: [3, 4, {:}]} | length | assert 3
        | length {:} | assert 0
      </data>
    """ |> assert!(0)
  end

  test "string" do
    ~S"""
      <data>
        | set "foo" | length  | assert 3
        | length "foo"        | assert 3
        | length ""           | assert 0
      </data>
    """ |> assert!(0)
  end

  test "tuple" do
    ~S"""
      <data>
        | set {1, 2, 3} | length    | assert 3
        | length {1, 2, 3}          | assert 3
        | length {}                 | assert 0
      </data>
    """ |> assert!(0)
  end

  test "nil" do
    ~S"""
      <data>
        | set nil | length    | assert 0
        | nil     | length    | assert 0
        | length nil          | assert 0
      </data>
    """ |> assert!(0)
  end

  test "numbers" do
    ~S"""
      <data>
        | set 0     | length   | assert 1
        | set 1     | length   | assert 1
        | set 10    | length   | assert 2
        | length 0             | assert 1
        | length 10            | assert 2
        | length -10           | assert 3
        | length nil
      </data>
    """ |> assert!(0)
  end

  test "invalid values" do
    ~S"""
      <data>
        | length | assert 0
        | length invalid | assert 0
      </data>
    """ |> assert!(0)
  end

end
