defmodule Dex.Service.UserTest do

  use ExUnit.Case, async: true
  alias Dex.Service.User

  setup do
    :ok
  end

  test "new" do
    assert :ok == User.put "foo", "foo", "foo@mail.domain"
    assert {:error, :user_already_exists} == User.new "foo", "foo", "foo@mail.domain"
    {:ok, user} = User.get "foo"
    assert user.id == "foo"
  end

end




