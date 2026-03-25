defmodule UnifiedIUR.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/pcharbon70/unified_ui"

  def project do
    [
      app: :unified_iur,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      description: "Canonical intermediate UI representation for the unified ecosystem.",
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
    []
  end

  defp docs do
    [
      main: "UnifiedIUR",
      extras: [
        "README.md",
        "guides/construct_families.md",
        "guides/core_model.md",
        "guides/interoperability.md",
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
