defmodule Dex.App.BuiltIn do

  use Dex.Common
  alias Dex.App
  require Logger

  @path "priv/scripts/"
  @builtin_apps [
    "_apps",
    "_test"
  ]

  def ensure do
    for app <- @builtin_apps do
      case App.create(App.default_userid, app, script app) do
        {:error, :app_already_exists} -> :ok
        :ok -> :ok
      end
      Logger.debug "ensure default apps deployed: #{app} -> ok."
    end
  end

  def update app_id do
    :ok = App.put(App.default_userid, app_id, String.trim(script app_id))
    Logger.debug "update -> #{app_id}, ok."
  end

  def update_all do
    Enum.each @builtin_apps, &(update &1)
  end

  def script app_id do
    file = @path <> app_id <> ".dex"
    File.read! file
  end

end
