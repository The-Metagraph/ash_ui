defmodule Mix.Tasks.AshUi.Example.BasicDashboard do
  @shortdoc "Render the basic dashboard example through a chosen adapter"

  @moduledoc """
  Renders the `examples/basic_dashboard` screen through a specific Ash UI
  adapter without starting a Phoenix server.

  ## Examples

      mix ash_ui.example.basic_dashboard --renderer liveview
      mix ash_ui.example.basic_dashboard --renderer elm --output /tmp/basic_dashboard.html
      mix ash_ui.example.basic_dashboard --renderer desktop

  By default the task uses the ETS-backed example data and ETS-backed UI
  storage resources that ship with the basic dashboard example.
  """

  use Mix.Task

  @switches [renderer: :string, output: :string, pretty: :boolean, strict_external: :boolean]
  @aliases [r: :renderer, o: :output]

  @impl Mix.Task
  @doc """
  Runs the basic dashboard adapter demo task.
  """
  def run(args) do
    Mix.Task.run("loadpaths")

    unless Code.ensure_loaded?(BasicDashboard.AdapterRunner) do
      Mix.raise(
        "Basic dashboard example modules are not available in this environment. " <>
          "Run the task with MIX_ENV=dev or MIX_ENV=test."
      )
    end

    {opts, positional, invalid} = OptionParser.parse(args, strict: @switches, aliases: @aliases)

    if positional != [] or invalid != [] do
      Mix.raise("Invalid arguments.\n\n" <> usage())
    end

    renderer =
      opts
      |> Keyword.get(:renderer, "elm")
      |> normalize_renderer!()

    case BasicDashboard.AdapterRunner.render(renderer, opts) do
      {:ok, result} ->
        formatted = BasicDashboard.AdapterRunner.format_output(result, opts)

        case Keyword.get(opts, :output) do
          nil ->
            Mix.shell().info(summary(result))
            IO.write(formatted)

            unless String.ends_with?(formatted, "\n") do
              IO.write("\n")
            end

          output_path ->
            File.write!(output_path, formatted)
            Mix.shell().info(summary(result))
            Mix.shell().info("Wrote rendered output to #{output_path}")
        end

      {:error, {:invalid_renderer, renderer_name}} ->
        Mix.raise("Unsupported renderer #{inspect(renderer_name)}.\n\n" <> usage())

      {:error, reason} ->
        Mix.raise("Failed to render basic dashboard example: #{inspect(reason)}")
    end
  end

  defp normalize_renderer!("liveview"), do: :liveview
  defp normalize_renderer!("live"), do: :liveview
  defp normalize_renderer!("elm"), do: :elm
  defp normalize_renderer!("desktop"), do: :desktop
  defp normalize_renderer!("native"), do: :desktop

  defp normalize_renderer!(other) do
    raise(Mix.Error, message: "Unsupported renderer #{inspect(other)}.\n\n" <> usage())
  end

  defp summary(result) do
    [
      "Renderer: #{result.renderer}",
      "Mode: #{result.mode}",
      "Adapter: #{inspect(result.adapter_module)}",
      "Selected module: #{inspect(result.selected_module)}",
      "Authoring module: #{result.authoring_module || "unknown"}",
      "Screen: #{result.screen.name}",
      ""
    ]
    |> Enum.join("\n")
  end

  defp usage do
    """
    Usage:
      mix ash_ui.example.basic_dashboard --renderer liveview|elm|desktop [--output PATH] [--pretty] [--strict-external]
    """
  end
end
