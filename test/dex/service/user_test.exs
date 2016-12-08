defmodule Dex.Service.UserTest do

  use ExUnit.Case, async: true
  alias Dex.Service.User

  setup do
    :ok
  end

  test "new" do
    assert :ok == User.new "foo", "foo@mail.com", "foo"
    {:ok, user} = User.get "foo"
    assert user.id == "foo"
  end

end




