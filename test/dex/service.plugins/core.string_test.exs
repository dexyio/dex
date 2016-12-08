defmodule Dex.Service.Plugins.Core.StringTest do

  use ExUnit.Case, async: false
  use Dex.Test

  setup do
    :ok
  end

  test "upcase" do
    ~S"""
      <data>
        | set "foo" | upcase 
      </data>
    """ |> assert!("FOO")
    ~S"""
      <data>
        | upcase "foo"
      </data>
    """ |> assert!("FOO")
    ~S"""
      <data>
        | upcase "Foo"
      </data>
    """ |> assert!("FOO")
  end

  test "downcase" do
    ~S"""
      <data>
        | set "FOO" | downcase 
      </data>
    """ |> assert!("foo")
    ~S"""
      <data>
        | downcase "FOO"
      </data>
    """ |> assert!("foo")
    ~S"""
      <data>
        | downcase "Foo"
      </data>
    """ |> assert!("foo")
  end

  test "trim" do
    ~S"""
    @dexyml
    | trim
    """ |> assert_raise!(Dex.Error.InvalidArgument)
    ~S"""
    @dexyml
    | trim ""
    """ |> assert!("")
    ~S"""
    @dexyml
    | trim "foo"
    """ |> assert!("foo")
    ~S"""
    @dexyml
    | trim "   foo\n\t"
    """ |> assert!("foo")
    ~S"""
    @dexyml
    | set "   foo\n\t" | trim
    """ |> assert!("foo")
    ~S"""
    @dexyml
    | set "   foo\n\t" | trim off: ""
    """ |> assert!("foo")
    ~S"""
    @dexyml
    | set "foo" | trim off: "o"
    """ |> assert!("f")
    ~S"""
    @dexyml
    | trim "foo", "o"
    """ |> assert!("f")
  end

end
