defmodule Dex.Sup do

  defmacro __using__(_opts) do
    quote do
      defmodule Supervisor do
        def start_link(args \\ []) do
          opts = [name: __MODULE__]
          Elixir.Supervisor.start_link(__MODULE__, args, opts)
        end

        def init(args) do
          sup_name = args[:name] || __MODULE__
          children = children(sup_name)
          opts = [strategy: args[:strategy] || :one_for_one]
          Elixir.Supervisor.Spec.supervise(children, opts)
        end

        def members do
          Elixir.Supervisor.which_children(__MODULE__)
            |> Enum.map(fn {name, pid, _, _} -> {name, pid} end)
        end

        defp children(sup_name) do
          children = Application.get_env(:dex, sup_name)[:children] || []
          for {type, spec} <- children do
            {mod, args, opts} = case spec do
              mod when is_atom(mod) -> {mod, [], []}
              {mod, args} -> {mod, args, []}
              full_spec = {_mod, _args, _opts} -> full_spec
            end
            apply Elixir.Supervisor.Spec, type, [mod, args, opts]
          end
        end
      end

      defp start_sup(args \\ []) do
        __MODULE__.Supervisor.start_link(args)
      end

      defp start_child(type, module, args \\ [], opts \\ []) do
        child = apply(Elixir.Supervisor.Spec, type, [module, args, opts])
        Elixir.Supervisor.start_child(__MODULE__.Supervisor, child)
      end
    end # qutoe
  end # defmacro

end

