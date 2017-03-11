defmodule Dex.Plugins.Core.SetTest do

  use ExUnit.Case, async: false
  use Dex.Test

  setup do
    :ok
  end

  test "tag" do
    ~S"""
    <data> foo </data>
    """ |> assert!(nil)

    ~S"""
    <data> "#{foo}" </data>
    """ |> assert!("")

    ~S"""
    <data> "hello, #{foo}" </data>
    """ |> assert!("hello, ")

    ~S"""
    <data> [1, foo, {}, {:}] </data>
    """ |> assert!([1, nil, {}, %{}])

    ~S"""
    <data> [1, "#{foo}", {}, {:}] </data>
    """ |> assert!([1, "", {}, %{}])

    ~S"""
    <data> {1, "2", {3: foo}} </data>
    """ |> assert!({1, "2", %{"3"=>nil}})

    ~S"""
    <data> {1, "2", {3: "#{foo}"}} </data>
    """ |> assert!({1, "2", %{"3"=>""}})

    ~S"""
    <data> {1, "2", {3: "#{foo}", 4: foo, 5: {6: foo}}} </data>
    """ |> assert!({1, "2", %{"3"=>"", "4"=>nil, "5"=>%{"6"=>nil}}})
  end

  test "pipescript" do
    ~S"""
    <data> | set 1 </data>
    """ |> assert!(1)

    ~S"""
    <data> | set 0.0123 </data>
    """ |> assert!(0.0123)

    ~S"""
    <data> | set "foo" </data>
    """ |> assert!("foo")

    ~S"""
    <data> | set true </data>
    """ |> assert!(true)

    ~S"""
    <data> | set false </data>
    """ |> assert!(false)

    ~S"""
    <data> | set nil </data>
    """ |> assert!(nil)

    ~S"""
    <data> | set foo </data>
    """ |> assert!(nil)

    ~S"""
    <data> | set Bar </data>
    """ |> assert!(nil)

    ~S"""
    <data> | set {} </data>
    """ |> assert!({})

    ~S"""
    <data> | set {1, "2", {3, [4]}} </data>
    """ |> assert!({1, "2", {3, [4]}})

    ~S"""
    <data> | set [] </data>
    """ |> assert!([])

    ~S"""
    <data> | set [1, "2", true, false, [3]] </data>
    """ |> assert!([1, "2", true, false, [3]])

    ~S"""
    <data> | set {:} </data>
    """ |> assert!(%{})

    ~S"""
    <data> | set { : } </data>
    """ |> assert!(%{})

    ~S"""
    <data> | set {a:1} </data>
    """ |> assert!(%{"a"=>1})

    ~S"""
    <data> | set "foo" | set "hello, #{data}" </data>
    """ |> assert!("hello, foo")

    ~S"""
    <data> | set "foo" | set ["hello", data] </data>
    """ |> assert!(["hello", "foo"])

    ~S"""
    <data> | set "foo" | set ["hello", "#{data}"] </data>
    """ |> assert!(["hello", "foo"])

    ~S"""
    <data> | set {1:1, foo:"2", bar:[3, {}], baz: {:}} </data>
    """ |> assert!(%{"1"=>1, "foo"=>"2", "bar"=>[3, {}], "baz"=>%{}})

    ~S"""
    <data>
      | set name: "foo"
      | set {bar:[3, {name}], baz: {name: name}}
    </data>
    """ |> assert!(%{"bar"=>[3, {"foo"}], "baz"=>%{"name"=>"foo"}})

    ~S"""
    <data>
      | set name: "foo"
      | set {bar:[3, {"#{name}"}], baz: {name: "#{name}"}}
    </data>
    """ |> assert!(%{"bar"=>[3, {"foo"}], "baz"=>%{"name"=>"foo"}})

    ~S"""
    <data>
      | set name: "foo"
      | set {bar:["#{name}", {"#{name}"}], baz: {name: "#{name}"}}
    </data>
    """ |> assert!(%{"bar"=>["foo", {"foo"}], "baz"=>%{"name"=>"foo"}})

    ~S"""
    <data>
      | set name: "foo"
      | set [{name, {bar:{name: "#{name}"}}}]
    </data>
    """ |> assert!([{"foo", %{"bar"=>%{"name"=>"foo"}}}])

    ~S"""
    <data>
      | set name: "foo"
      | set {[{name, {bar:{name: "#{name}"}}}]}
    </data>
    """ |> assert!({[{"foo", %{"bar"=>%{"name"=>"foo"}}}]})

    ~S"""
    <data> | set {{1:1, foo:"2", bar:[3, {}], baz: {:}}} </data>
    """ |> assert!({%{"1"=>1, "foo"=>"2", "bar"=>[3, {}], "baz"=>%{}}})

    ~S"""
    <data> | set {{1:1, foo:"2", bar:[3, {}], baz: {:}}, {}} </data>
    """ |> assert!({%{"1"=>1, "foo"=>"2", "bar"=>[3, {}], "baz"=>%{}}, {}})

    ~S"""
    <data> | set [{1: 1, foo: "2", bar: [3, {}], baz: {:}}] </data>
    """ |> assert!([%{"1"=>1, "foo"=>"2", "bar"=>[3, {}], "baz"=>%{}}])

    ~S"""
    <data> | set [{1: 1, foo: "2", bar: [3, {}], baz: {:}}, {}] </data>
    """ |> assert!([%{"1"=>1, "foo"=>"2", "bar"=>[3, {}], "baz"=>%{}}, {}])
  end

  test "map" do
    ~S"""
    <data>
      | set name: "Foo"
      | set age: 10
      | set {name: name, age: age}
    </data>
    """ |> assert!(%{"name"=>"Foo", "age"=>10})

    ~S"""
    <data>
      | set my.name: "Foo"
      | set my.age: 10
      | set my
    </data>
    """ |> assert!(%{"name"=>"Foo", "age"=>10})

    ~S"""
    <data>
      | set my.name: "Foo"
      | set my.family: [{name: "Bar", age: 1}]
      | set my.family
    </data>
    """ |> assert!([%{"name"=>"Bar", "age"=>1}])
  end

  test "characters" do
    ~S"""
    <data> "hello world" </data>
    """ |> assert!("hello world")
  end

  test "unicode" do
    ~S"""
    <data>
      | set 베어: true
      | set 베어
    </data>
    """ |> assert!(true)
  end

end
