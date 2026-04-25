defmodule AshUIExamples.AlertDialog.MixProject do
  use Mix.Project

  def project do
    [
      app: :ash_ui_example_alert_dialog,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      mod: {AshUIExamples.AlertDialog.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ash_ui, path: "../.."},
      {:phoenix, "~> 1.7"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_view, "~> 1.0"},
      {:plug_cowboy, "~> 2.7"}
    ]
  end

  defp aliases do
    [
      "example.start": ["phx.server"]
    ]
  end
end
