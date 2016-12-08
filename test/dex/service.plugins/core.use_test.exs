defmodule Dex.Service.Plugins.Core.UseTest do

  use ExUnit.Case, async: false
  use Dex.Test

  setup do
    :ok
  end

  test "foo" do
    ~S"""
    @dexyml
    @use user_foo/app_bar as: foo
    | foo.echo
    """ |> assert_raise!(Dex.Error.AppNotFound)
  end

  test "bar" do
    ~S"""
    @dexyml

    @cdata
    <fn:foo test=''>
      <fn/>
    </fn:foo>

    | test
    """ |> assert!("<fn/>")
  end

end
