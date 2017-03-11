defmodule Dex.Plugins.App do

  use Dex.Common
  use Dex.Helper
  alias Dex.App

  def get state = %{args: []} do do_get state, data! state end
  def get state = %{args: [data]} do do_get state, data end

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
    res = with \
      %App{} <- App.parse!(user.id, body),
      :ok <- App.put(user.id, app_id, body)
    do "ok" else
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
    res = with \
      %App{} <- App.parse!(user.id, body),
      :ok <- App.create(user.id, app_id, body)
    do "ok" else
      {:error, reason} -> to_string reason
    end
    {state, res}
  end

  def disable state = %{args: [app_id]} do
    state |> auth_basic!() |> do_disable(app_id)
  end
  
  defp do_disable state = %{user: user}, app_id do
    res = case App.disable user.id, app_id do
      :ok -> "ok"
      {:error, reason} ->  to_string reason
    end
    {state, res}
  end

  def delete state = %{args: [app_id]} do
    state |> auth_basic!() |> do_delete(app_id)
  end

  defp do_delete state = %{user: user}, app_id do
    res = case App.delete user.id, app_id do
      :ok -> "ok"
      {:error, reason} ->  to_string reason
    end
    {state, res}
  end

end
