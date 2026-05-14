defmodule Mix.Tasks.DesktopUi.Inspect do
  use Mix.Task

  @shortdoc "Prints inspection output for a maintained desktop_ui example"

  @moduledoc """
  Prints inspection output for a maintained `desktop_ui` example.

      mix desktop_ui.inspect native_styled_review
      mix desktop_ui.inspect styled_continuity_review --format comparison
      mix desktop_ui.inspect native_foundational --format host
      mix desktop_ui.inspect --format catalog
  """

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")
    {opts, positional, _invalid} = OptionParser.parse(args, switches: [format: :string])
    format = Keyword.get(opts, :format, "report")

    case {format, positional} do
      {"catalog", _} ->
        Mix.shell().info(
          Kernel.inspect(DesktopUi.Inspect.catalog(),
            pretty: true,
            width: 100,
            limit: :infinity,
            sort_maps: true
          )
        )

      {chosen_format, [example_id]} ->
        inspect_format =
          case chosen_format do
            "report" -> :report
            "metadata" -> :metadata
            "comparison" -> :comparison
            "diagnostics" -> :diagnostics
            "host" -> :host
            other -> Mix.raise("unsupported inspect format #{inspect(other)}")
          end

        case DesktopUi.Inspect.render(example_id, inspect_format) do
          {:ok, output} ->
            Mix.shell().info(output)

          {:error, reason} ->
            Mix.raise("unable to inspect example #{inspect(example_id)}: #{inspect(reason)}")
        end

      _ ->
        Mix.raise(
          "usage: mix desktop_ui.inspect [EXAMPLE_ID] [--format report|metadata|comparison|diagnostics|host|catalog]"
        )
    end
  end
end
