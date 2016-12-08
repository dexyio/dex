defmodule Dex.Service.Plugins.Core.FilterTest do

  use ExUnit.Case, async: false
  use Dex.Test

  setup do
    :ok
  end

  test "filter" do
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
  end

end
