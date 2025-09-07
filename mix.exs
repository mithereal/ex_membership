defmodule Membership.MixProject do
  use Mix.Project

  @version "1.0.6"
  @source_url "https://github.com/mithereal/ex_membership"

  def project do
    [
      app: :ex_membership,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      description: description(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test
      ],
      package: package(),
      docs: docs(),
      dialyzer: dialyzer()
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :runtime_tools],
      mod: {Membership.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.10"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0", optional: true},
      {:myxql, ">= 0.0.0", optional: true},
      {:ecto_sqlite3, ">= 0.0.0", optional: true},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:optimus, "~> 0.1.0", only: :dev},
      {:mix_test_watch, "~> 0.8", only: :dev, runtime: false},
      {:ex_machina, "~> 2.2", only: :test},
      {:faker, "~> 0.16", only: [:test, :dev]},
      {:excoveralls, "~> 0.14", only: [:test, :dev]},
      {:mock, "~> 0.3.0", only: :test},
      {:inch_ex, only: :docs},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev, :test], runtime: false},
      {:mix_audit, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:ice_cream, "~> 0.0.5", only: [:dev, :test]},
      {:nanoid, ">= 2.0.0"}
    ]
  end

  defp description() do
    "Elixir ACL library for managing user features, plans and roles with support of ecto and compatibility with absinthe"
  end

  defp package() do
    [
      files: ~w(lib priv/repo/migrations .formatter.exs mix.exs README*),
      licenses: ["GPL"],
      links: %{"GitHub" => "https://github.com/mithereal/ex_membership"}
    ]
  end

  defp docs() do
    [
      extras: ["README.md"],
      main: "readme",
      homepage_url: @source_url,
      source_ref: "v#{@version}",
      source_url: @source_url,
      groups_for_modules: [
        Models: [
          Membership.Member,
          Membership.Plan,
          Membership.Role
        ]
      ]
    ]
  end

  defp dialyzer() do
    [
      plt_add_deps: :transitive,
      plt_add_apps: [:ex_unit, :mix],
      flags: [
        :error_handling,
        :race_conditions,
        :underspecs,
        :unmatched_returns
      ]
    ]
  end

  defp aliases do
    [
      c: "compile",
      test: [
        "ecto.drop --quiet",
        "ecto.create --quiet",
        "ecto.migrate --quiet",
        "test"
      ],
      c: "compile",
      setup: ["run priv/repo/seeds.exs"],
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      install: ["Membership.install", "ecto.setup"]
    ]
  end
end
