defmodule DexTest do

  use ExUnit.Case
  use Dex.Test

  setup do
    :ok
  end

  test "@text document" do
    ~S"""
    @text
    """ |> assert!("")
    ~S"""
    @text
    hello world
    """ |> assert!("hello world")
    ~S"""
    hello world
    """ |> assert!("hello world")
  end

  test "@dexyml document" do
    ~S"""
    @dexyml
    """ |> assert!(nil)
    ~S"""
    @dexyml
    "hello world"
    """ |> assert!("hello world")
    ~S"""
    | set "hello world"
    """ |> assert!("hello world")
  end

  test "function not found" do
    ~S"""
    @dexyml
    | set nil
    | #$@$@$
    """ |> assert_raise!(Dex.Error.FunctionNotFound)
  end

  test "syntax error" do
    ~S"""
    <data>
    """ |> assert_raise!(Dex.Error.SyntaxError)
    ~S"""
    @dexyml
    aksdljfals;kjfa;ksjfkl
    """ |> assert_raise!(Dex.Error.SyntaxError)
    ~S"""
    @dexyml
    | length {{
    """ |> assert_raise!(Dex.Error.SyntaxError)
    ~S"""
    @dexyml
    | set nil
    | length ksjfdlss;slf;
    """ |> assert_raise!(Dex.Error.SyntaxError)
    ~S"""
    @dexyml
    <do>
      $5#$$!@#
    </do>
    """ |> assert_raise!(Dex.Error.SyntaxError)
    ~S"""
    @dexyml
    | set a: $%@$%@$
    """ |> assert_raise!(Dex.Error.SyntaxError)
  end

end
