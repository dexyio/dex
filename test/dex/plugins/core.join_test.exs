defmodule Dex.Plugins.Core.JoinTest do

  use ExUnit.Case, async: false
  use Dex.Test

  setup do
    :ok
  end

  test "arity 0 with default joiner" do
    ~S"""
      <data>
        | set 1..3 | join
      </data>
    """ |> assert!("123")
    ~S"""
      <data>
        | set [1, 2, 3] | join
      </data>
    """ |> assert!("123")
    ~S"""
      <data>
        | set {1, 2, 3} | join
      </data>
    """ |> assert!("123")
    ~S"""
      <data>
        | set "123" | for | join
      </data>
    """ |> assert!("123")
  end

  test "arity 0 with custom joiner" do
    ~S"""
      <data>
        | set 1..3 | join ""
      </data>
    """ |> assert!("123")
    ~S"""
      <data>
        | set [1, 2, 3] | join " "
      </data>
    """ |> assert!("1 2 3")
    ~S"""
      <data>
        | set {1, 2, 3} | join ","
      </data>
    """ |> assert!("1,2,3")
    ~S"""
      <data>
        | set "123" | for | join "0"
      </data>
    """ |> assert!("10203")
  end

  test "arity 1 default joiner" do
    ~S"""
      <data>
        | join 1..3 
      </data>
    """ |> assert!("123")
    ~S"""
      <data>
        | join [1, 2, 3] 
      </data>
    """ |> assert!("123")
  end

  test "error" do
    ~S"""
      <data>
        | set [1, 2, 3] | join 1, 2, 3
      </data>
    """ |> assert_raise!(Dex.Error.BadArity)
    ~S"""
      <data>
        | set {:} | join
      </data>
    """ |> assert_raise!(Dex.Error.InvalidArgument)
    ~S"""
      <data>
        | set [1, 2, 3] | join wrong
      </data>
    """ |> assert_raise!(Dex.Error.InvalidArgument)
  end

end
