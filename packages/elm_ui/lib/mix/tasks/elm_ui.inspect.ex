defmodule Mix.Tasks.ElmUi.Inspect do
  use Mix.Task

  @shortdoc "Prints inspection output for a maintained elm_ui example"

  @moduledoc """
  Prints inspection output for a maintained `elm_ui` example.

      mix elm_ui.inspect native_styling
      mix elm_ui.inspect canonical_styling --format diagnostics
      mix elm_ui.inspect styling_continuity --format comparison
      mix elm_ui.inspect --format catalog
  """

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")
    {opts, positional, _invalid} = OptionParser.parse(args, switches: [format: :string])
    format = Keyword.get(opts, :format, "report")

    case {format, positional} do
      {"catalog", _} ->
        Mix.shell().info(
          Kernel.inspect(ElmUi.Inspect.catalog(),
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
            other -> Mix.raise("unsupported inspect format #{inspect(other)}")
          end

        case ElmUi.Inspect.render(example_id, inspect_format) do
          {:ok, output} ->
            Mix.shell().info(output)

          {:error, reason} ->
            Mix.raise("unable to inspect example #{inspect(example_id)}: #{inspect(reason)}")
        end

      _ ->
        Mix.raise(
          "usage: mix elm_ui.inspect [EXAMPLE_ID] [--format report|metadata|comparison|diagnostics|catalog]"
        )
    end
  end
end
