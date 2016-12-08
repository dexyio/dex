defmodule Dex.FSM do

  defmacro __using__(opts \\ []) do
    keychange = fn (props, from, to) ->
      List.keyreplace(props, from, 0, {to, props[from]})
    end

    opts = keychange.(opts, :state, :initial_state)
    opts = keychange.(opts, :data, :initial_data)

    quote do
      use Fsm, unquote(opts)
    end
  end

end


