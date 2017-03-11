defmodule Dex.Plugins.HTTPTest do

  use ExUnit.Case, async: false
  use Dex.Test

  setup do
    :ok
  end

  test "on_call" do
    ~S"""
    @dexyml
    | http.get "http://www.example.com"
    | set data.code
    """ |> assert!(200)
  end

end
