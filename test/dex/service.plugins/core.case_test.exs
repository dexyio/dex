defmodule Dex.Service.Plugins.Core.CaseTest do

  use ExUnit.Case, async: false
  use Dex.Test

  setup do
    :ok
  end

  test "case do" do
    ~S"""
    <data>
      | case do
      | end
    </data>
    """ |> assert!(nil)

    ~S"""
    <data>
      | case do
      |   when nil | set true
      |   when | set false
      | end
    </data>
    """ |> assert!(true)

    ~S"""
    <data>
      | case do
      |   when nil | set true
      |   when | set false
      | end
    </data>
    """ |> assert!(true)

    ~S"""
    <data>
      | case false do
      |   when false | set true
      |   when true | set false
      | end
    </data>
    """ |> assert!(true)
  end

end
