defmodule Dex.Service.Plugins.App do

  use Dex.Common
  use Dex.Service.Helper
  alias Dex.Service.App

  def get state do
    auth_basic!(state) |> get_
  end

  defp get_ state = %{args: []} do do_get state, data! state end
  defp get_ state = %{args: [data]} do do_get state, data end

  defp do_get state = %{user: user}, app_id do
    case App.get(user.id, app_id) do
      {:ok, app} ->
        app = Map.from_struct(app)
          |> Map.delete(:nodes)
          |> Enum.into(%{}, fn {k, v} -> {to_string(k), v} end)
        {state, app}
      _ ->
        {state, nil}
    end
  end

  def put state do
    auth_basic!(state) |> put_
  end

  defp put_ state = %{args: [app_id, body]} do
    do_put state, app_id, body
  end

  defp do_put state = %{user: user}, app_id, body do
    res = case App.put user.id, app_id, body do
      :ok -> "ok"
      {:error, reason} -> to_string reason
    end
    {state, res}
  end

  def post state do
    auth_basic!(state) |> post_
  end

  defp post_ state = %{args: [app_id, body]} do
    do_post state, app_id, body
  end
 
  defp do_post state = %{user: user}, app_id, body do
    res = case App.new user.id, app_id, body do
      :ok -> "ok"
      {:error, reason} -> to_string reason
    end
    {state, res}
  end

  def delete state do
    auth_basic!(state) |> delete_
  end

  defp delete_ state = %{args: [app_id]} do
    do_delete state, app_id
  end

  defp do_delete state = %{user: user}, app_id do
    res = case App.del user.id, app_id do
      :ok -> "ok"
      {:error, reason} ->  to_string reason
    end
    {state, res}
  end

end
