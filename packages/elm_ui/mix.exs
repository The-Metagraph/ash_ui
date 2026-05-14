defmodule ElmUi.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/pcharbon70/unified_ui"

  def project do
    [
      app: :elm_ui,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      description: "Phoenix-and-Elm runtime library for the unified web target.",
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:jido_signal, "~> 2.0"},
      {:phoenix, "~> 1.8"},
      {:unified_iur, path: "../unified_iur"}
    ]
  end

  defp docs do
    [
      main: "ElmUi",
      extras: [
        "README.md",
        "guides/runtime_backbone.md",
        "guides/native_runtime_and_examples.md",
        "guides/canonical_rendering_and_transport.md",
        "guides/styling_and_inspection.md",
        "guides/maintainer_workflows.md"
      ],
      source_ref: "main",
      source_url: @source_url
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
