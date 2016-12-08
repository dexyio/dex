defmodule Dex.Service.Plugins.Core.DoTest do

  use ExUnit.Case, async: false
  use Dex.Test

  setup do
    :ok
  end

  test "characters" do
    ~S"""
    <data>
      <do/>
    </data>
    """ |> assert!(nil)
    ~S"""
    <data>
      <do> "foo" </do>
    </data>
    """ |> assert!("foo")
    ~S"""
    <data>
      <do> foo </do>
    </data>
    """ |> assert!(nil)
    ~S"""
    <data>
      <do> Foo </do>
    </data>
    """ |> assert!(nil)
    ~S"""
    <data>
      <do> [1, "2", [3], {}, {4}, {:}, {5: "6"}] </do>
    </data>
    """ |> assert!([1, "2", [3], {}, {4}, %{}, %{"5"=>"6"}])
    ~S"""
    <data>
      <do> <foo/> </do>
    </data>
    """ |> assert_raise!(Dex.Error.SyntaxError)
    ~S"""
    <data>
      <do>
        <foo/>
      </do>
    </data>
    """ |> assert_raise!(Dex.Error.SyntaxError)
    ~S"""
    <data>
      @cdata <do> <foo/> </do>
    </data>
    """ |> assert!("<foo/>")
    ~S"""
    <data>
      @cdata <do>
        <html/>
      </do>
    </data>
    """ |> assert!("<html/>")
    ~S"""
    <data>
      @cdata <do>
        | set nil
      </do>
    </data>
    """ |> assert!("| set nil")
  end

  test "pipescript" do
    ~S"""
    <data>
      <do> | set true  </do>
    </data>
    """ |> assert!(true)
    ~S"""
    <data>
      @lang pipescript <do> set true  </do>
    </data>
    """ |> assert!(true)
    ~S"""
    <data>
      @lang pipescript <do> | set true  </do>
    </data>
    """ |> assert!(true)
    ~S"""
    <data>
      <do> set true </do>
    </data>
    """ |> assert_raise!(Dex.Error.CompileError)
  end

  test "variable scope" do
    ~S"""
    <data>
      <do>
        | set a: 1, b: 2
        | set a+b
        | assert 3
      </do>

      <do>
        | set a
        | assert nil
      </do>
    </data>
    """ |> assert!(nil)
  end

end
