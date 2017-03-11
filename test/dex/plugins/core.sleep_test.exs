defmodule Dex.Plugins.Core.SleepTest do

  use ExUnit.Case, async: false
  use Dex.Test

  setup do
    :ok
  end

  test "foo" do
    ~S"""
    @dexyml
    | set true
    | sleep 1_000
    """ |> assert!(true)
  end

end
