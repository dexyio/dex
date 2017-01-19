defmodule Dex.Service.Plugins.CoreTest do

  use ExUnit.Case, async: false
  use Dex.Test

  doctest Dex.Service.Plugins.Core

  setup do
    :ok
  end

  test "type check" do
    ~S"""
    @dexyml
    | is_nil                    | assert true
    | set 1       | is_number   | assert true
    | set 1       | is_integer  | assert true
    | set 1.0     | is_float    | assert true
    | set "hello" | is_string   | assert true
    | set [1,2,3] | is_list     | assert true
    | set {}      | is_tuple    | assert true
    | set {:}     | is_map      | assert true
    | set 1..10   | is_range    | assert true
    | set ~r/foo/ | is_regex    | assert true
    """ |> assert!(true)
  end

  test "basic arithmetic" do
    ~S"""
    @dexyml
    | set 1 + 2   | assert 3
    | set 5 * 5   | assert 25
    | set 10 / 2  | assert 5.0
    | set 0b1010  | assert 10
    | set 0o777   | assert 511
    | set 0x1F    | assert 31
    | nil
    """ |> assert!(nil)
    ~S"""
    @dexyml
    | set a: 2, b: 1
    | set a - b   | assert 1
    | nil
    """ |> assert!(nil)
  end

  test "div & rem" do
    ~S"""
    @dexyml
    | set 10 / 2      | assert 5.0
    | div 10, 2       | assert 5
    | set 10 | div 2  | assert 5
    | set div(10, 2)  | assert 5
    | nil
    """ |> assert!(nil)
  end

  test "round, trunc, ceil, floor" do
    ~S"""
    @dexyml
    | round 123
    | nil
    """ |> assert!(nil)
  end

  test "list" do
    ~S"""
    @dexyml
    | set [1, 1, 3] -- [1, 2]
    """ |> assert!([1, 3])
  end

  test "to_number" do
    ~S"""
    @dexyml
    | to_number "123" 
    """ |> assert!(123)
  end

  test "pipescript" do
    ~S"""
    @dexyml
    <fn foo=''>
      "hello world"
    </fn>
    | set foo()
    """ |> match!("hello world")
  end

  test "html" do
    ~S"""
    @html
    <html/>
    """ |> match!(%{})
  end

  test "javascript" do
    ~S"""
    @javascript
    return 1+1;
    """ |> assert!(2)

    ~S"""
    @javascript
    var f = function(a) { return a + 1; }
    return f(1)
    """ |> assert!(2)
  end

  test "access array & tuple" do
    ~S"""
    @dexyml
    | set [1, 2, 3] | set data:0      | assert 1
    | set [1, 2, 3] | set data:10     | assert nil
    | set [1, 2, 3] | set data:-1     | assert 3
    | set [1, 2, 3] | set data:-10    | assert nil
    """ |> assert!(nil)
    ~S"""
    @dexyml
    | set list: [1, 2, 3]
    | set list[0]   | assert 1
    | set list[-1]  | assert 3
    | set list[1,]  | assert [2, 3]
    | nil
    """ |> assert!(nil)
    ~S"""
    @dexyml
    | set tupl: {1, 2, 3}
    | set tupl[0]   | assert 1
    | set tupl[-1]  | assert 3
    | nil
    """ |> assert!(nil)
  end

  test "unicode in map, list, tuple" do
    ~S"""
    @dexyml
    | set 동물원.가족: ["토끼", "호랑이", "여우", "늑대", "곰"]
    | set 동물원[0]
    """ |> assert!({"가족", ["토끼", "호랑이", "여우", "늑대", "곰"]})
    ~S"""
    @dexyml
    | set 동물원.가족: ["토끼", "호랑이", "여우", "늑대", "곰"]
    | set 동물원.가족[-1]
    """ |> assert!("곰")
    ~S"""
    @dexyml
    | set 동물원.가족: {"토끼", "호랑이", "여우", "늑대", "곰"}
    | set 동물원.가족[1]    | assert "호랑이"
    | set 동물원.가족[100]  | assert nil
    | set 동물원.가족[-100] | assert nil
    """ |> assert!(nil)
    ~S"""
    @dexyml
    | set 동물원.가족: {"토끼", "호랑이", "여우", "늑대", "곰"}
    | set 동물원.가족[2,,3]
    """ |> assert!(["여우", "늑대"])
  end

  test "array bracket with range" do
    ~S"""
    @dexyml
    | set 1..5
    | set data[,]       | assert [1, 2, 3, 4, 5]
    | set data[,,]      | assert [1, 2, 3, 4, 5]
    | set data[,,,,-1]  | assert [1, 2, 3, 4, 5]
    | set data[,,-1]    | assert [1, 2, 3, 4, 5]
    | set data[,-1]     | assert [1, 2, 3, 4, 5]
    | set data[0,]      | assert [1, 2, 3, 4, 5]
    | set data[0,,]     | assert [1, 2, 3, 4, 5]
    | set data[0,,,]    | assert [1, 2, 3, 4, 5]
    | nil
    """ |> assert!(nil)
  end

  test "array bracket with list" do
    ~S"""
    @dexyml
    | set val: 1..5 | to_list
    | set val[1,3,]          | assert [2, 4, 5]
    | set val[,1,3,]         | assert [1, 2, 4, 5]
    | set val[foo]           | assert nil
    | set val[foo, bar]      | assert [nil, nil]
    | set val[true, false]   | assert [nil, nil]
    | set val[0, foo]        | assert [1, nil]
    | set val[,foo]          | assert nil
    | set val[foo,]          | assert nil

    | set val[no]            | assert nil
    | set no: -1
    | set val[no]            | assert 5
    | set val["bad"]         | assert nil
    | set val[no, "bad"]     | assert [5, nil]
    | set val[10, 1, no]     | assert [nil, 2, 5]
    | nil
    """ |> assert!(nil)
    ~S"""
    @dexyml
    | set val: ["horse", "dog", "cat"]
    | set val[no]          | assert nil

    | set no: 2
    | set val[no]          | assert "cat"
    | set val["bad"]       | assert nil
    | set val[no, "bad"]   | assert ["cat", nil]
    | set val[10, 1, no]   | assert [nil, "dog", "cat"]
    | nil
    """ |> assert!(nil)
  end

  test "array bracket with tuple" do
    ~S"""
    @dexyml
    | set val: to_tuple(1..5) 
    | set val[1,3,]          | assert [2, 4, 5]
    | set val[,1,3,]         | assert [1, 2, 4, 5]
    | set val[foo]           | assert nil
    | set val[foo, bar]      | assert [nil, nil]
    | set val[true, false]   | assert [nil, nil]
    | set val[0, foo]        | assert [1, nil]
    | set val[,foo]          | assert nil
    | set val[foo,]          | assert nil

    | set val[no]            | assert nil
    | set no: -1
    | set val[no]            | assert 5
    | set val["bad"]         | assert nil
    | set val[no, "bad"]     | assert [5, nil]
    | set val[10, 1, no]     | assert [nil, 2, 5]
    | nil
    """ |> assert!(nil)
  end

  test "array bracket with string" do
    ~S"""
    @dexyml
    | set val: "12345"
    | set val[1,3,]          | assert ["2", "45"]
    | set val[,1,3,]         | assert ["12", "45"]
    | set val[foo]           | assert nil
    | set val[foo, bar]      | assert [nil, nil]
    | set val[true, false]   | assert [nil, nil]
    | set val[0, foo]        | assert ["1", nil]
    | set val[,foo]          | assert nil
    | set val[foo,]          | assert nil

    | set val[no]            | assert nil
    | set no: -1
    | set val[no]            | assert "5"
    | set val["bad"]         | assert nil
    | set val[no, "bad"]     | assert ["5", nil]
    | set val[10, 1, no]     | assert [nil, "2", "5"]
    | nil
    """ |> assert!(nil)
  end

  test "variables in array bracket" do
    ~S"""
    @dexyml
    | set var: "name"
    | set my[var]: "foo"
    | set my.name
    """ |> assert!("foo")
    ~S"""
    @dexyml
    | set var: "name"
    | set my[var2]: "foo"
    | set my.name
    """ |> assert!(nil)
    ~S"""
    @dexyml
    | set animals: ["foo", "bar", "baz"]
    | set my.bar: 1  | set animals[my.bar] | assert "bar"
    | set my.bar: -1 | set animals[my.bar] | assert "baz"
    | set my.bar: 10 | set animals[my.bar] | assert nil
    | set my.bar: -9 | set animals[my.bar] | assert nil
    """ |> assert!(nil)
    ~S"""
    @dexyml
    // correct
    | set my.farm.dogs: ["foo", "bar", "baz"]
    | set my.farm["dogs"][0]      | assert "foo"
    | set my.farm["dogs"][9]      | assert nil
    | set my["farm"].dogs[-1]     | assert "baz"
    | set my["farm"].dogs[-9]     | assert nil
    | set my.farm.dogs:0          | assert "foo"
    | set my["farm"].dogs:9       | assert nil
    | set my.bad["dogs"][0]       | assert nil
    | set my["farm"]["dogs"][0]   | assert "foo"
    | set my["farm"]["dogs"][9]   | assert nil
    | set my["farm"]["dogs"][-1]  | assert "baz"
    | set my["farm"]["dogs"][-9]  | assert nil
    | set my["farm"]["dogs"]:0    | assert "foo"
    | set my["farm"]["dogs"]:9    | assert nil
    | set my["farm"]["dogs"]:-1   | assert "baz"
    | set my["farm"]["dogs"]:-9   | assert nil
    // incorrect
    | set my.farm["dogs"]:-1      | assert "baz"
    | set my.farm["bad"][0]       | assert nil
    """ |> assert!(nil)
  end

  test "multiple in array bracket" do
    ~S"""
    @dexyml
    | set animals: ["foo", "bar", "baz"]
    | set n: 2   | set animals[n:0]   | assert "foo"
    | set n: 10  | set animals[n:10]
    """ |> assert!(nil)
  end

  test "type casting" do
    ~S"""
    @dexyml
    | nil           | to_string | assert ""
    | set 1         | to_string | assert "1"
    | set "foo"     | to_string | assert "foo"
    | set []        | to_string | assert "[]"
    | set {}        | to_string | assert "{}"
    | set {1, 2, 3} | to_string | assert "{1, 2, 3}"
    | set {:}       | to_string | assert "{}"
    | set {a:1,b:1} | to_string | assert "{\"b\":1,\"a\":1}"
    | nil
    """ |> assert!(nil)
    ~S"""
    @dexyml
    | nil           | to_map | assert {:}
    | nil
    """ |> assert!(nil)
  end

end
