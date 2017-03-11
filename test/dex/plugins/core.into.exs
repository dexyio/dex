defmodule Dex.Plugins.Core.IntoTest do

  use ExUnit.Case, async: false
  use Dex.Test

  setup do
    :ok
  end

  test "the true" do
    ~S"""
    @dexyml
    | set 1
    | set 2 | into "foo"
    | assert foo: 2
    """ |> assert!(2)
  end

end
