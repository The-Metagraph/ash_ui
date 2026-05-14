defmodule UnifiedUi.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/pcharbon70/unified_ui"

  def project do
    [
      app: :unified_ui,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      description: "Authored DSL and canonical IUR compiler for the unified ecosystem.",
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
      {:spark, "~> 2.4", override: true},
      {:unified_iur, path: "../unified_iur"}
    ]
  end

  defp docs do
    [
      main: "UnifiedUi",
      extras: [
        "README.md",
        "docs/README.md",
        "docs/user/getting-started.md",
        "docs/user/widget-catalog.md",
        "docs/user/layouts-layers-and-display.md",
        "docs/user/styling-and-themes.md",
        "docs/user/bindings-and-interactions.md",
        "docs/user/canonical-navigation.md",
        "docs/developer/architecture-overview.md",
        "docs/developer/dsl-section-model.md",
        "docs/developer/compilation-pipeline.md",
        "docs/developer/package-components.md",
        "docs/developer/canonical-navigation.md",
        "guides/dsl_model.md",
        "guides/theming_and_signals.md",
        "guides/compiler_and_parity.md",
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
