defmodule Dex.Service.Plugins.Core.IfUnlessTest do

  use ExUnit.Case, async: false
  use Dex.Test

  setup do
    :ok
  end

  test "foo" do
    ~S"""
    <data>
      | set a: 1
      | set true if a: 1
    </data>
    """ |> assert!(true)
  end

  test "if" do
    ~S"""
    <data>
      | if | assert nil
    </data>
    """ |> assert!(nil)
    ~S"""
    <data>
    </data>
    """ |> assert!(nil)
    ~S"""
    <data>
      | if nil do | true | else | false | end | assert false
      | if nil do: | true | else | false
      | assert false
    </data>
    """ |> assert_raise!(Dex.Error.AssertionFailed)
    ~S"""
    <data>
      | if nil do
      |   set "true"
      | else
      |   set "false"
      | end
    </data>
    """ |> assert!("true")
    ~S"""
    <data>
      | set true
      | set "true" if: true | set "false"
    </data>
    """ |> assert!("true")
    ~S"""
    <data>
      | set false
      | set "true" if: true | set "false"
    </data>
    """ |> assert!("false")
    ~S"""
    <data>
      | set false if: nil
    </data>
    """ |> assert!(false)
    ~S"""
    <data>
      | set 1 | set data + 1 if: nil
    </data>
    """ |> assert!(1)
    ~S"""
    <data>
      | set 1 | set data * 10 / 2  if: true
    </data>
    """ |> assert!(5)
    ~S"""
    <data>
      | set 1 if: true | set 10 | set data + 1
    </data>
    """ |> assert!(11)
    ~S"""
    <data>
      | set 1 if: true | set 10 | set data + 1
    </data>
    """ |> assert!(11)
  end

  test "temp" do
    ~S"""
    <data>
      | unless nil do | true | else | false | end
    </data>
    """ |> assert!(false)
  end

  test "unless" do
    ~S"""
    <data>
      | unless nil do | true | else | false | end | assert false
      | unless false do: | true | else | false
    </data>
    """ |> assert!(false)
    ~S"""
    <data>
      | set true unless: nil | false
    </data>
    """ |> assert!(false)
    ~S"""
    <data>
      | unless nil do | set "true" | else | set "false" | end
    </data>
    """ |> assert!("false")
    ~S"""
    <data>
      | set "true" unless: nil | set "false"
    </data>
    """ |> assert!("false")
    ~S"""
    <data>
      | set false unless: nil
    </data>
    """ |> assert!(nil)
    ~S"""
    <data>
      | set false unless: nil | set 1 | set data + 1
    </data>
    """ |> assert!(2)
    ~S"""
    <data>
      | set false unless: nil
      | set 1 | set data + 1
    </data>
    """ |> assert!(2)
  end

  test "regex" do
    ~S"""
    <data>
      | set "foo"
      | true if: ~r/^foo$/ | false
    </data>
    """ |> assert!(true)
    ~S"""
    <data>
      | set "foobar"
      | true if: ~r/foobar/u | false
    </data>
    """ |> assert!(true)
    ~S"""
    <data>
      | set "foo"
      | true if: ~r/bar/ | false
    </data>
    """ |> assert!(false)
  end

  test "nest" do
    ~S"""
    @dexyml
    | if true do
    |   if true do: | set 1
    | end
    """ |> assert!(nil)
  end

end
