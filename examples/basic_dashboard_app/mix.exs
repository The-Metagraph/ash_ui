defmodule BasicDashboardApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :basic_dashboard_app,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      listeners: [Phoenix.CodeReloader],
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      mod: {BasicDashboardApp.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(_env), do: ["lib", Path.expand("../basic_dashboard/lib", __DIR__)]

  defp deps do
    [
      {:ash_ui, path: "../.."},
      {:phoenix, "~> 1.8"},
      {:phoenix_html, "~> 4.3"},
      {:phoenix_live_view, "~> 1.1"},
      {:plug_cowboy, "~> 2.7"},
      {:jason, "~> 1.4"},
      {:unified_iur, path: "../../packages/unified_iur"},
      {:live_ui, path: "../../packages/live_ui"},
      {:web_ui, path: "../../packages/web_ui"},
      {:desktop_ui, path: "../../packages/desktop_ui"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.create -r AshUI.Repo", "ecto.migrate -r AshUI.Repo"],
      reset: ["ecto.drop -r AshUI.Repo", "setup"],
      test: ["ecto.create -r AshUI.Repo --quiet", "ecto.migrate -r AshUI.Repo", "test"]
    ]
  end
end
