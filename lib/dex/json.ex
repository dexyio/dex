defmodule Dex.JSON do

  defmacro __using__(opts) do
    quote do
      alias unquote(__MODULE__), unquote(opts)
    end
  end # defmacro

  def decode!(json) do
    Poison.decode! json
  end

  def encode!(data, _options \\ []) do
    Poison.encode! data
  end
  
end

