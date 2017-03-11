defmodule Dex.Plugins.Core.CoffeescriptTest do

  use ExUnit.Case, async: false
  use Dex.Test

  setup do
    :ok
  end

  test "correct" do
    ~S"""
    @dexyml
    @lang coffeescript
    <do/>
    """ |> assert!(nil)
    ~S"""
    @dexyml
    @lang coffeescript
    <do>
      square = (x) -> x * x
      return square(1) 
    </do>
    """ |> assert!(1)
    ~S"""
    @dexyml
    @lang coffeescript
    <fn square='x'>
      square = () -> x * x
      return square(1) 
    </fn>

    | square 1
    """ |> assert!(1)
  end

  test "math.js" do
    ~S"""
    @coffeescript

    song = ["do", "re", "mi", "fa", "so"]

    singers = {Jagger: "Rock", Elvis: "Roll"}

    bitlist = [
    1, 0, 1
      0, 0, 1
      1, 1, 0
    ]

    kids =
      brother:
        name: "Max"
        age:  11
      sister:
        name: "Ida"
        age:  9

    return singers
    """ |> assert!(nil)
  end

end
