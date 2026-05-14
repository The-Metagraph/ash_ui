defmodule Mix.Tasks.LiveUi.Inspect do
  use Mix.Task

  @shortdoc "Prints inspection output for a maintained live_ui example"

  @moduledoc """
  Prints inspection output for a maintained `live_ui` example.

      mix live_ui.inspect button
      mix live_ui.inspect table --format diagnostics
      mix live_ui.inspect button --format style
      mix live_ui.inspect button --format comparison
      mix live_ui.inspect --format catalog
  """

  alias LiveUi.Export

  @impl Mix.Task
  def run(args) do
    {opts, positional, _invalid} = OptionParser.parse(args, switches: [format: :string])
    format = Keyword.get(opts, :format, "report")

    case {format, positional} do
      {"catalog", _} ->
        Mix.shell().info(Export.catalog())

      {chosen_format, [example_id]} ->
        export_format =
          case chosen_format do
            "report" -> :report
            "metadata" -> :metadata
            "comparison" -> :comparison
            "diagnostics" -> :diagnostics
            "style" -> :style
            other -> Mix.raise("unsupported inspect format #{inspect(other)}")
          end

        case Export.example(example_id, export_format) do
          {:ok, output} ->
            Mix.shell().info(output)

          {:error, reason} ->
            Mix.raise("unable to inspect example #{inspect(example_id)}: #{inspect(reason)}")
        end

      _ ->
        Mix.raise(
          "usage: mix live_ui.inspect [EXAMPLE_ID] [--format report|metadata|comparison|diagnostics|style|catalog]"
        )
    end
  end
end
