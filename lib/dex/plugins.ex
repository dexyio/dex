defmodule Dex.Plugins do

  defmacro __using__(_opts) do
    Application.get_env(:dex, __MODULE__)
      |> Enum.map(fn {_, mod} ->
        quote do: alias unquote(mod)
      end)
  end # defmacro

end

