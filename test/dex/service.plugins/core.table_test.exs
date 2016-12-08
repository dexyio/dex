defmodule Dex.Service.Plugins.Core.TableTest do

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
