defmodule AshUITutorials.LiveDiagnostics.MixProject do
  use Mix.Project

  @default_runtime "live_ui"
  @supported_runtimes ["live_ui", "elm_ui", "desktop_ui"]
  @runtime_aliases %{
    "desktop" => "desktop_ui",
    "desktop_ui" => "desktop_ui",
    "elm" => "elm_ui",
    "elm_ui" => "elm_ui",
    "live" => "live_ui",
    "live-ui" => "live_ui",
    "live_ui" => "live_ui",
    "liveview" => "live_ui"
  }

  def project do
    [
      app: :ash_ui_tutorial_live_diagnostics,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      mod: {AshUITutorials.LiveDiagnostics.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ash_ui, path: "../../.."},
      {:phoenix, "~> 1.7"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_view, "~> 1.0"},
      {:plug_cowboy, "~> 2.7"}
    ]
  end

  defp aliases do
    [
      "example.start": [&example_start/1]
    ]
  end

  defp example_start(args) do
    {opts, positional} = OptionParser.parse!(args, strict: [runtime: :string])

    runtime =
      Keyword.get(opts, :runtime) ||
        case positional do
          [] -> @default_runtime
          [value] -> value
          _ -> Mix.raise("expected zero or one runtime argument, e.g. `mix example.start elm_ui`")
        end

    runtime = normalize_runtime!(runtime)

    System.put_env("ASH_UI_EXAMPLE_RUNTIME", runtime)
    Mix.shell().info("Starting tutorial application with runtime=#{runtime}")
    Mix.Task.run("phx.server", [])
  end

  defp normalize_runtime(runtime) when is_binary(runtime) do
    runtime =
      runtime
      |> String.trim()
      |> String.downcase()

    case Map.fetch(@runtime_aliases, runtime) do
      {:ok, canonical} -> {:ok, canonical}
      :error -> {:error, {:unsupported_runtime, runtime, @supported_runtimes}}
    end
  end

  defp normalize_runtime!(runtime) do
    case normalize_runtime(runtime) do
      {:ok, canonical} ->
        canonical

      {:error, {:unsupported_runtime, value, supported}} ->
        Mix.raise(
          "unsupported runtime #{inspect(value)}; expected one of: #{Enum.join(supported, ", ")}"
        )
    end
  end
end
