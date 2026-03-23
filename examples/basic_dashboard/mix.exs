defmodule BasicDashboardExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :basic_dashboard_example,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      mod: {BasicDashboardExample.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp deps do
    [
      {:ash_ui, path: "../.."},
      {:phoenix, "~> 1.7.14"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_view, "~> 1.0"},
      {:plug_cowboy, "~> 2.7"},
      {:jason, "~> 1.4"},
      {:unified_iur, path: "../../packages/unified_iur"},
      {:live_ui, path: "../../packages/live_ui"},
      {:elm_ui, path: "../../packages/elm_ui"},
      {:desktop_ui, path: "../../packages/desktop_ui"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"]
    ]
  end
end
