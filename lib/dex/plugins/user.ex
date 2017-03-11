defmodule Dex.Plugins.User do

  use Dex.Common
  use Dex.Helper
  alias Dex.User
  require Dex.Code

  def new state = %{args: [userid, passwd, email]} do 
    do_new state, {userid, passwd, email}
  end

  defp do_new(state, {userid, passwd, email})
  when is_bitstring(userid) and is_bitstring(passwd) and is_bitstring(email) do
    case User.new userid, passwd, email do
      :ok -> {state, "ok"}
      {:error, :user_already_exists} ->  {state, "UserAlreadyExists"}
    end
  end

end
