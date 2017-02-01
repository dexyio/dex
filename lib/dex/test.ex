defmodule Dex.Test do
  
  use Dex.Common
  alias DexyLib.Mappy
  alias Dex.Service.App

  defmodule Helper do
    def id, do: "foo"

    def user, do: %Dex.Service.User{
      id: id(), 
      __secret: sha256(id() <> ":" <> id()),
      enabled: true
    }

    def request, do: %Dex.Service.Request{
      user: id(),
      app: "test",
      fun: "GET",
      args: ["arg1", 2, 3..10],
      opts: %{"foo" => "bar", "bar" => "baz"},
      header: %{
        "authorization" => ~s/Basic #{Base.encode64("foo:foo")}/
      }
    }

    def request_props app, fun, args \\ [], opts \\ %{} do
      [
        user: id(),
        app: app,
        fun: fun,
        args: args,
        opts: opts,
        header: %{
          "authorization" => ~s/Basic #{Base.encode64("foo:foo")}/,
        },
        body: "",
        callback: self()
      ]
    end

  end

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end  # defmacro

  defmacro assert? result, expected_value do
    quote do
      result = unquote(result)
      expected_value = unquote(expected_value)
      assert result == expected_value
    end
  end

  defmacro assert! script, expected_value do
    quote do
      result = do! unquote(script)
      expected_value = unquote(expected_value)
      assert result == expected_value
    end
  end

  defmacro match! script, expected_value do
    quote do
      result = do! unquote(script)
      assert unquote(expected_value) = result 
    end
  end

  defmacro catch_throw! script, expected_value do
    quote do
      assert unquote(expected_value) = catch_throw(do! unquote script)
    end
  end

  defmacro assert_raise! script, expected_value do
    quote do
      assert_raise unquote(expected_value), fn -> do! unquote script end
    end
  end

  def do!(script) when is_bitstring(script) do
    script = String.trim_leading script
    app = %App{} = App.parse! user = Helper.id, script
    delete_purge_module mod = "DEX.USERS.#{String.upcase user}.TEST"
    {mod, _bin} = App.compile! app, mod
    js = Dex.JS.take_handle
    state = mod._F0 %Dex.Service.State{
      req: Helper.request, user: Helper.user, app: app, js: js
    }
    Dex.JS.return_handle js
    Mappy.val(state.mappy, "data")
  end

  def do!(script) when is_list(script) do
    script |> to_string |> do!
  end

  defp delete_purge_module(mod) when is_bitstring(mod) do
    "Elixir.#{mod}" |> String.to_atom |> delete_purge_module
  end

  defp delete_purge_module(mod) when is_atom(mod) do
    :code.delete(mod); :code.purge(mod)
  end

end
