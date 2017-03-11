defmodule Dex.Plugins.Core.FilterTest do

  use ExUnit.Case, async: false
  use Dex.Test

  setup do
    :ok
  end

  test "correct" do
    ~S"""
      <data>
        | set 1..3 | filter do: | is_true data > 1
      </data>
    """ |> assert!([2, 3])
    ~S"""
      <data>
        | filter 1..3 do: | is_true data > 1
      </data>
    """ |> assert!([2, 3])
    ~S"""
      <data>
        | filter 1..3, wrong do: | is_true data > 1
      </data>
    """ |> assert_raise!(Dex.Error.BadArity)
    ~S"""
      <data>
        | set 3 | filter do: | is_true data > 1
      </data>
    """ |> assert!([2, 3])
    ~S"""
      <data>
        | set [1, 2, 3] | filter do: | is_true data > 1
      </data>
    """ |> assert!([2, 3])
    ~S"""
      <data>
        | set {1, 2, 3} | filter do: | is_true data > 1
        | assert [2, 3]
        | to_tuple
      </data>
    """ |> assert!({2, 3})
    ~S"""
      <data>
        | set "123" | filter do: | is_true data > "1"
        | assert ["2", "3"]
        | join
      </data>
    """ |> assert!("23")
    ~S"""
    @dexyml

    <fn test1=''>
    | filter [1, 2, 3, "foo", "bar"] do
    |   is_number
    | end
    | assert [1, 2, 3]
    </fn>

    <fn test2=''>
    | filter [1, 2, 3, "foo", "bar"] do
    |   is_string
    | end
    | assert ["foo", "bar"]
    </fn>

    <fn test3=''>
    | [1, 2, 3, "foo", "bar"] | filter do: is_number
    | assert [1, 2, 3] 
    </fn>

    <fn test4=''>
    | filter [1, 2, 3, "foo", "bar"] do: is_string
    | assert ["foo", "bar"]
    </fn>

    <fn test5=''>
    | filter 1..10 do: | is_true rem(data, 2) == 0
    | assert [2, 4, 6, 8, 10]
    </fn>

    | test1
    | test2
    | test3
    | test4
    | test5
    | set "all passed"
    """ |> assert!("all passed")
  end

end
