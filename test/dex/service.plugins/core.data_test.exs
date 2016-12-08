defmodule Dex.Service.Plugins.Core.DataTest do

  use ExUnit.Case, async: false
  use Dex.Test

  setup do
    :ok
  end

  test "data" do
    ~S"""
    <data/>
    """ |> assert!(nil)

    ~S"""
    <data></data>
    """ |> assert!(nil)

    ~S"""
    <data> 1 </data>
    """ |> assert!(1)

    ~S"""
    <data> 0.0123 </data>
    """ |> assert!(0.0123)

    ~S"""
    <data> "foo" </data>
    """ |> assert!("foo")

    ~S"""
    <data> true </data>
    """ |> assert!(true)

    ~S"""
    <data> false </data>
    """ |> assert!(false)

    ~S"""
    <data> nil </data>
    """ |> assert!(nil)

    ~S"""
    <data> foo </data>
    """ |> assert!(nil)

    ~S"""
    <data> Bar </data>
    """ |> assert!(nil)

    ~S"""
    <data> {} </data>
    """ |> assert!({})

    ~S"""
    <data> {1, "2", {3, [4]}} </data>
    """ |> assert!({1, "2", {3, [4]}})

    ~S"""
    <data> [] </data>
    """ |> assert!([])

    ~S"""
    <data> [1, "2", true, false, [3]] </data>
    """ |> assert!([1, "2", true, false, [3]])

    ~S"""
    <data> {:} </data>
    """ |> assert!(%{})

    ~S"""
    <data> {a:nil} </data>
    """ |> assert!(%{"a"=>nil})

    ~S"""
    <data> {a:true} </data>
    """ |> assert!(%{"a"=>true})

    ~S"""
    <data> {a:false} </data>
    """ |> assert!(%{"a"=>false})

    ~S"""
    <data> { : } </data>
    """ |> assert!(%{})

    ~S"""
    <data> {a:1} </data>
    """ |> assert!(%{"a"=>1})

    ~S"""
    <data> {1:1, foo:"2", bar:[3, {}], baz: {:}} </data>
    """ |> assert!(%{"1"=>1, "foo"=>"2", "bar"=>[3, {}], "baz"=>%{}})

    ~S"""
    <data> {{1:1, foo:"2", bar:[3, {}], baz: {:}}} </data>
    """ |> assert!({%{"1"=>1, "foo"=>"2", "bar"=>[3, {}], "baz"=>%{}}})
    
    ~S"""
    <data> {{1:1, foo:"2", bar:[3, {}], baz: {:}}, {}} </data>
    """ |> assert!({%{"1"=>1, "foo"=>"2", "bar"=>[3, {}], "baz"=>%{}}, {}})

    ~S"""
    <data> [{1:1, foo:"2", bar:[3, {}], baz: {:}}] </data>
    """ |> assert!([%{"1"=>1, "foo"=>"2", "bar"=>[3, {}], "baz"=>%{}}])

    ~S"""
    <data> [{1: 1, foo: "2", bar: [3, {}], baz: {:}}, {}] </data>
    """ |> assert!([%{"1"=>1, "foo"=>"2", "bar"=>[3, {}], "baz"=>%{}}, {}])
  end

  test "error" do
    ~S"""
    <data>
    """ |> assert_raise!(Dex.Error.SyntaxError)
    ~S"""
    <data>
      ...
    </data>
    """ |> assert_raise!(Dex.Error.CompileError)
  end

end
