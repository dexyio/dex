defmodule Dex.Service.Vnode do

  require Logger
  use Dex.Common
  alias Dex.Service.Request
  alias Dex.Service.User
  alias Dex.Service.Bot

  @behaviour :riak_core_vnode

  defmacro bucket, do: __MODULE__ |> DexyLib.to_binary

  # Callbacks

  def start_vnode(partition) do
    :riak_core_vnode_master.get_vnode_pid(partition, __MODULE__)
  end

  def init([partition]) do
    {:ok, %{partition: partition}}
  end

  def handle_command :ping, sender, state = %{partition: partition} do
    Logger.debug("got a ping request! sender: #{inspect sender}")
    {:reply, {:pong, partition}, state}
  end

  def handle_command req = %Request{user: user_id}, _from, state = %{partition: part} do
    Logger.debug("got a request! => #{inspect req}")
    res = with \
      :undefined <- :gproc.lookup_local_name(user_id),
      user = %User{} <- get_user!(user_id),
      {:ok, pid} <- Bot.new(user),
      :ok <- store_bot(part, user_id)
    do
      Bot.request(pid, req)
    else
      {:error, reason} -> {:error, reason}
      pid when is_pid(pid) -> Bot.request(pid, req)
    end
    {:reply, res, state}
  end

  def handle_handoff_command(_fold_req, _sender, state) do
    {:noreply, state}
  end

  def handoff_starting(_target_node, state) do
    {true, state}
  end

  def handoff_cancelled(state) do
    {:ok, state}
  end

  def handoff_finished(_target_node, state) do
    {:ok, state}
  end

  def handle_handoff_data(_data, state) do
    {:reply, :ok, state}
  end

  def encode_handoff_item(_object_name, _object_value) do
    ""
  end

  def is_empty(state) do
    {true, state}
  end

  def delete(state) do
    {:ok, state}
  end

  def handle_coverage(_req, _key_spaces, _sender, state) do
    {:stop, :not_implemented, state}
  end

  def handle_exit(_pid, _reason, state) do
    {:noreply, state}
  end

  def terminate(_reason, _state) do
    :ok
  end

  # Private functions
  defp store_bot partition, user_name do
    key = {:partition, partition} |> DexyLib.to_binary
    Dex.KV.put bucket, key, user_name
  end

  defp get_user! user_id do
    case User.get(user_id) do
      {:ok, user} ->
        user.enabled && user || {:error, :user_disabled}
      {:error, reason} ->
        {:error, reason}
    end
  end

end
