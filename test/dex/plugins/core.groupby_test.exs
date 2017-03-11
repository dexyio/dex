defmodule Dex.Plugins.Core.GroupByTest do

  use ExUnit.Case, async: false
  use Dex.Test

  setup do
    :ok
  end

  test "foo" do
    ~S"""
    @dexyml
    """ |> assert!(nil)
  end

end
