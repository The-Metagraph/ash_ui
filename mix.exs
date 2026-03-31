defmodule AshUI.MixProject do
  use Mix.Project

  def project do
    [
      app: :ash_ui,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [
        summary: [threshold: coverage_threshold()],
        ignore_modules: coverage_ignore_modules()
      ],
      dialyzer: dialyzer(),
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {AshUI.Application, []}
    ]
  end

  defp elixirc_paths(:dev), do: ["lib", "dev", "examples/basic_dashboard/lib"]
  defp elixirc_paths(:test), do: ["lib", "test/support", "examples/basic_dashboard/lib"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ash, "~> 3.0"},
      {:ash_postgres, "~> 2.0"},
      {:phoenix_live_view, "~> 1.0"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:igniter, "~> 0.6", only: [:dev, :test]},
      {:jason, "~> 1.4"},
      {:postgrex, ">= 0.0.0"},
      {:ecto_sql, "~> 3.10"},
      {:simple_sat, "~> 0.1"},
      {:telemetry, "~> 1.0"},
      {:uuid, "~> 1.1"},
      {:unified_ui, path: "packages/unified_ui"},
      {:unified_iur, path: "packages/unified_iur"},
      {:live_ui, path: "packages/live_ui", optional: true},
      {:elm_ui, path: "packages/elm_ui", optional: true},
      {:desktop_ui, path: "packages/desktop_ui", optional: true}
    ]
  end

  defp aliases do
    [
      format: ["format"]
    ]
  end

  defp dialyzer do
    [
      ignore_warnings: ".dialyzer_ignore.exs",
      plt_add_apps: [:mix]
    ]
  end

  defp coverage_threshold do
    System.get_env("MIX_TEST_COVERAGE_THRESHOLD", "90")
    |> String.to_integer()
  end

  defp coverage_ignore_modules do
    [
      ~r/^Inspect\./,
      ~r/^AshUI\.Test\./,
      ~r/^BasicDashboardExample(?:\.|$)/
    ]
  end
end
