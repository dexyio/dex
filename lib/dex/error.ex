defmodule Dex.Error do

  import Dex

  defmacro __using__(_opts) do
    quote do
      alias unquote(__MODULE__)
      import unquote(__MODULE__)
    end
  end # defmacro

  deferror AccessDenied
  deferror AppAliasOmitted
  deferror AppAllocationFailed
  deferror AppNotExported
  deferror AppNotFound
  deferror AppLoadingFailed
  deferror ArithmeticError
  deferror AssertionFailed
  
  deferror BadArity
  deferror BotCreationFailed

  deferror CompileError
  
  deferror FunctionNotFound
  deferror FunctionCallError
  deferror FunctionClauseError
  deferror FunctionDepthOver

  deferror InvalidAnnotation
  deferror InvalidArgument
  deferror InvalidDocFormat
  deferror InvalidTag

  deferror JavascriptError

  deferror NoFreeSeats

  deferror RuntimeError

  deferror CacheBcuketCreationFailed

  deferror ServiceTimeout
  deferror SyntaxError

  deferror UserAlreadyExists
  deferror UserNotFound
  deferror Unauthorized

  deferror Stopped

end
