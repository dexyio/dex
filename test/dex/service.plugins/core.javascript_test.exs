defmodule Dex.Service.Plugins.Core.JavascriptTest do

  use ExUnit.Case, async: false
  use Dex.Test

  setup do
    :ok
  end

  test "correct" do
    ~S"""
    @dexyml
    @lang javascript
    <fn return_nil='x'></fn>
    | return_nil
    """ |> assert!(nil)
    ~S"""
    @dexyml
    @lang javascript
    <fn return_nil='x'>
      return x;
    </fn>

    | return_nil
    """ |> assert!(nil)
    ~S"""
    @dexyml
    @lang javascript
    <fn foo='' b='1' c='2'>
      return b + c;
    </fn>

    | foo
    """ |> assert!(3)
    ~S"""
    <data>
      @lang javascript <do> return 0; </do>
    </data>
    """ |> assert!(0)
    ~S"""
    <data>
      @lang javascript <do> return 1+1; </do>
    </data>
    """ |> assert!(2)
    ~S"""
    <data>
      @lang javascript <do> return "foo" </do>
    </data>
    """ |> assert!("foo")
    ~S"""
    <data>
      @lang javascript
      <do> return {a: 1, b: "foo"} </do>
    </data>
    """ |> assert!(%{"a"=>1, "b"=>"foo"})
    ~S"""
    <data>
      @lang javascript <do/>
    </data>
    """ |> assert!(nil)
  end

  test "incorrect" do
    ~S"""
    @dexyml
    @lang javascript
    <fn return_nil='x'>
      1
    </fn>
    """ |> assert_raise!(Dex.Error.SyntaxError)
  end

end
