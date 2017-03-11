defmodule Dex.Plugins.Core.MapTest do

  use ExUnit.Case, async: false
  use Dex.Test

  setup do
    :ok
  end

  test "foo" do
    ~S"""
    <data>
      | map foo: 1, bar: 1..10
    </data>
    """ |> assert!(%{"foo"=>1, "bar"=>1..10})

    ~S"""
    <data>
      | map foo: 1, bar: 1..10
    </data>
    """ |> assert!(%{"foo"=>1, "bar"=>1..10})

    ~S"""
    <data>
      | map 푸우: 1, 베어: "곰돌이"
    </data>
    """ |> assert!(%{"푸우"=>1, "베어"=>"곰돌이"})

    ~S"""
    <data>
      | map 푸우: 1
    </data>
    """ |> assert!(%{"푸우"=>1})
  end

end
