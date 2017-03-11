defmodule Dex.User.EventHandler do

  defstruct foo: nil

  use GenEvent
  alias Dex.Bot
  require Logger

  # Callbacks

  def init _args do
    state = %__MODULE__{}
    {:ok, state}
  end

  def handle_event msg = {:new_user, _user_id}, state do
    Logger.debug inspect(msg)
    {:ok, state}
  end

  def handle_event msg = {:user_updated, user_id}, state do
    Logger.debug inspect(msg)
    Bot.reload_user user_id
    {:ok, state}
  end

  def handle_call :ping, state do
    {:ok, :pong, state}
  end

end
