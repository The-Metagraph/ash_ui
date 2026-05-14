defmodule Mix.Tasks.ElmUi.Export do
  use Mix.Task

  @shortdoc "Prints a stable exported representation of a maintained elm_ui example"

  @moduledoc """
  Prints a stable exported representation of a maintained `elm_ui` example.

      mix elm_ui.export native_styling
      mix elm_ui.export styling_continuity --format comparison
      mix elm_ui.export canonical_styling --format diagnostics
      mix elm_ui.export --format catalog
  """

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")
    {opts, positional, _invalid} = OptionParser.parse(args, switches: [format: :string])
    format = Keyword.get(opts, :format, "report")

    case {format, positional} do
      {"catalog", _} ->
        Mix.shell().info(
          Kernel.inspect(ElmUi.Export.catalog(),
            pretty: true,
            width: 100,
            limit: :infinity,
            sort_maps: true
          )
        )

      {chosen_format, [example_id]} ->
        export_format =
          case chosen_format do
            "report" -> :report
            "metadata" -> :metadata
            "comparison" -> :comparison
            "diagnostics" -> :diagnostics
            other -> Mix.raise("unsupported export format #{inspect(other)}")
          end

        case ElmUi.Export.example(example_id, export_format) do
          {:ok, output} ->
            Mix.shell().info(output)

          {:error, reason} ->
            Mix.raise("unable to export example #{inspect(example_id)}: #{inspect(reason)}")
        end

      _ ->
        Mix.raise(
          "usage: mix elm_ui.export [EXAMPLE_ID] [--format report|metadata|comparison|diagnostics|catalog]"
        )
    end
  end
end
