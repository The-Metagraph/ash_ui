defmodule Mix.Tasks.ElmUi.Preview do
  use Mix.Task

  @shortdoc "Prints preview output for a maintained elm_ui example"

  @moduledoc """
  Prints preview output for a maintained `elm_ui` example.

      mix elm_ui.preview
      mix elm_ui.preview native_styling
      mix elm_ui.preview canonical_styling --format metadata
  """

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")
    {opts, positional, _invalid} = OptionParser.parse(args, switches: [format: :string])
    format = Keyword.get(opts, :format, "report")

    case positional do
      [] ->
        Mix.shell().info(
          Kernel.inspect(ElmUi.Inspect.catalog(),
            pretty: true,
            width: 100,
            limit: :infinity,
            sort_maps: true
          )
        )

      [example_id] ->
        preview_format =
          case format do
            "report" -> :report
            "metadata" -> :metadata
            other -> Mix.raise("unsupported preview format #{inspect(other)}")
          end

        case ElmUi.Inspect.render(example_id, preview_format) do
          {:ok, output} ->
            Mix.shell().info(output)

          {:error, reason} ->
            Mix.raise("unable to preview example #{inspect(example_id)}: #{inspect(reason)}")
        end

      _ ->
        Mix.raise("usage: mix elm_ui.preview [EXAMPLE_ID] [--format report|metadata]")
    end
  end
end
