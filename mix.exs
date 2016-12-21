defmodule Dex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :dex,
      name: "Dex",
      version: "0.1.0-dev",
      deps_path: "deps",
      lockfile: "mix.lock",
      elixir: "~> 1.3",
      deps: deps,
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      source_url: "https://github.com/datamelodies/dex",
      homepage_url: "http://datamelodi.es",
      docs: [
        extras: ["GettingStarted.md", "Examples.md"]
      ]
    ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [
      applications: applications(Mix.env),
      included_applications: [
        :pooler
      ],
      mod: {Dex, []}
    ]
  end
  
  defp applications :prod do
    [
      :logger,
      :timex,
      :gproc,
      :erlsom,
      :poison,
      :socket,
      :erlang_js,
      :erlang_v8, 
      :con_cache,
      :riak_core,
      :bamboo,
      :httpoison,
    ]
  end

  defp applications :test do
    applications(:prod) -- [
      :riak_core
    ]
  end

  defp applications(_), do: applications :prod


  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:myapp, in_umbrella: true}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:dexy_lib, github: "dexyio/dexy_lib"},
      {:dexy_plugin_json, github: "dexyio/dexy_plugin_json"},

      {:con_cache, "~> 0.11.1"},
      {:ex_doc, "~> 0.14", only: :dev},
      {:exrm, "~> 1.0.0-rc7"},
      {:erlsom, "~> 1.2"},
      {:gproc, "~> 0.6.1"},
      {:matrix, "~> 0.3.0"},
      {:poison, "~> 3.0", override: true}, #{:jsone, "~> 1.2"}, 
      {:pooler, "~> 1.5"},
      {:riakc, "~> 2.1"},
      {:riak_core, ">= 2.2.6", hex: :riak_core_ng},
      {:socket, "~> 0.3"},
      {:timex, "~> 3.0"},
      {:httpoison, "~> 0.10.0"},
      {:bamboo, "~> 0.7"},

      {:erlang_js, github: "basho/erlang_js", branch: "develop"},
      {:erlang_v8, github: "strange/erlang_v8", compile: "make"},
      {:jsx, "~> 2.8", override: true},

      #{:jobs, github: "uwiger/jobs"},
      #{:gproc, github: "uwiger/gproc"},
    ]
  end
end
