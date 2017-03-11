defmodule Dex.App.EventHandler do

  defstruct foo: nil

  use GenEvent
  alias Dex.App
  require Logger

  # Callbacks

  def init _args do
    state = %__MODULE__{}
    {:ok, state}
  end

  def handle_event msg = {:app_updated, user_id, app_id}, state do
    Logger.debug inspect(msg)
    App.Pool.on_app_updated user_id, app_id
    {:ok, state}
  end

  def handle_event msg = {:app_disabled, user_id, app_id}, state do
    Logger.debug inspect(msg)
    App.Pool.on_app_disabled user_id, app_id
    {:ok, state}
  end

  def handle_event msg, state do
    Logger.warn inspect(msg)
    {:ok, state}
  end

  def handle_call msg, state do
    Logger.warn inspect(msg)
    {:ok, :undefined, state}
  end

  # Private functions

end
