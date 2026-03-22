defmodule LiveUI.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_ui,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: []
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end
end
