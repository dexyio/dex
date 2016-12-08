defmodule Dex.Service.Plugins.Core.SplitTest do

  use ExUnit.Case, async: false
  use Dex.Test

  setup do
    :ok
  end

  test "string" do
    ~S"""
    @dexyml
    | set "foo,bar,baz"
    | split ","
    | count
    """ |> assert!(3)

    ~S"""
    @dexyml
    | set "foo bar   baz"
    | split | count
    """ |> assert!(3)
  end

  test "csv" do
    ~S"""
    @dexyml
    @cdata
    <fn text=''>
      foo1,bar1,baz1
      foo2,bar2,baz2
      foo3,bar3,baz3
    </fn>

    | lines text()
    | for do: | split ","
    """ |> assert!(
      [
        ["foo1", "bar1", "baz1"],
        ["foo2", "bar2", "baz2"],
        ["foo3", "bar3", "baz3"]
      ]
    )
  end

  test "tsv and tuple" do
    ~S"""
    @dexyml
    @cdata
    <fn text=''>
      foo 1\tbar 1\tbaz 1
      foo 2\tbar 2\tbaz 2
      foo 3\tbar 3\tbaz 3
    </fn>

    | lines text()
    | for do 
    |   split ~r/\t+/
    |   to_tuple 
    | end
    """ |> assert!(
      [
        {"foo 1", "bar 1", "baz 1"},
        {"foo 2", "bar 2", "baz 2"},
        {"foo 3", "bar 3", "baz 3"}
      ]
    )
  end

end
