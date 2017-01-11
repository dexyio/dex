defmodule Dex.Common do

  import Logger

  defmacro __using__(_opts) do
    quote do
      use Dex.Error
      use DexyLib
      alias DexyLib, as: Lib
      require Dex.Service.Code, as: Code
      import unquote(__MODULE__)
      
      def conf(mod \\ __MODULE__) do
        Application.get_env(:dex, mod)
      end
    end
  end

  defmacro nilstr, do: "\0"

  def wait_until(fun), do: wait_until(fun, 20, 500)
  
  def wait_until(_, 0, _), do: :fail

  def wait_until(fun, retry, delay) when is_function(fun) and retry > 0 do
    if fun.() do
      :ok
    else
      Process.sleep(delay)
      wait_until(fun, retry-1, delay)
    end
  end

  def md5(str) do
    :crypto.hash(:sha256, str)
  end

  def sha256(str) do
    :crypto.hash(:sha256, str)
  end

  def sha512(str) do
    :crypto.hash(:sha512, str)
  end
  
  def print_warn(msg) do
    warn inspect msg
  end

  def print_error(msg) do
    do_print_error msg
    error inspect System.stacktrace
  end

  defp do_print_error(msg) when is_atom(msg) or is_bitstring(msg) do
    error msg
  end

  defp do_print_error(msg), do: error inspect msg

end
