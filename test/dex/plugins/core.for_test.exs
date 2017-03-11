defmodule Dex.Plugins.Core.ForTest do

  use ExUnit.Case, async: false
  use Dex.Test

  setup do
    :ok
  end

  test "range" do
    ~S"""
      <data>
        | for 1..10 
      </data>
    """ |> assert!(1..10 |> Enum.to_list)
    ~S"""
      <data>
        | for 1..10 do | end
      </data>
    """ |> assert!(1..10 |> Enum.to_list)
    ~S"""
      <data>
        | set 1..10 | for 
      </data>
    """ |> assert!(1..10 |> Enum.to_list)
    ~S"""
      <data>
        | set 1..10 | for do | end
      </data>
    """ |> assert!(1..10 |> Enum.to_list)
    ~S"""
      <data>
        | for 1..10 do
        |   set data + 1
        | end
      </data>
    """ |> assert!(2..11 |> Enum.to_list)
  end

  test "list" do
    ~S"""
      <data>
        | for [1, 2, 3] 
      </data>
    """ |> assert!([1, 2, 3])
  end

  test "map" do
    ~S"""
      <data>
        | for {a:1, b:2} do | end
      </data>
    """ |> assert!([{"a", 1}, {"b", 2}])
    ~S"""
      <data>
        | for {a:1, b:2} do: | set data:0
      </data>
    """ |> assert!(["a", "b"])
    ~S"""
      <data>
        | for {a:1, b:2} do: | set data:1
      </data>
    """ |> assert!([1, 2])
  end

  test "string" do
    ~S"""
      <data>
        | for "hello" do | end
      </data>
    """ |> assert!(["h", "e", "l", "l", "o"])
  end

  test "unicode" do
    ~S"""
      <data>
        | for "안녕" do | end
      </data>
    """ |> assert!(["안", "녕"])
    ~S"""
      <data>
        | set x: "안녕" | for x | join
        | assert x
      </data>
    """ |> assert!("안녕")
  end

  test "when" do
    ~S"""
    @dexyml
    | for 1..3 do 
    |   when 1 | set data + 1
    |   else   | set data * 2
    | end
    """ |> assert!([2, 4, 6])
    ~S"""
    @dexyml
    | set 1..3 | for do 
    |   when 1 | set data + 1
    |   else   | set data * 2
    | end
    """ |> assert!([2, 4, 6])
    ~S"""
    @dexyml
    | set 1..3 | for do 
    |   set data * 2
    |   when 1 | set data + 1
    | end
    """ |> assert!([2, 4, 6])
    ~S"""
    @dexyml
    | set 1..3
    | for do
    |   true if: data > 1
    | end
    """ |> assert!([1, true, true])
    ~S"""
    @dexyml
    | set 1..3
    | for do: | true if: data > 1
    """ |> assert!([1, true, true])
    ~S"""
    @dexyml
    | set 1..3 | for do: | set data * 2 | when 1 | set data + 1
    | set 1..3 | for do: | when 1 | set data + 1 | else | set data * 2
    """ |> assert!([2, 4, 6])
    ~S"""
    @dexyml
    | set 1..3 | for do 
    |   set data * 2
    |   when 1 | set data + 1
    | end
    | sum
    """ |> assert!(12)
    ~S"""
    @dexyml
    | set 1..1000 | for 
    | sum
    """ |> assert!(500500)
  end

end
