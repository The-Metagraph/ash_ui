defmodule Mix.Tasks.UnifiedUi.Export do
  use Mix.Task

  @shortdoc "Prints exported UnifiedUi example or module output for review"

  @moduledoc """
  Prints review-friendly exported output for `UnifiedUi` examples or modules.

      mix unified_ui.export --example foundational_screen
      mix unified_ui.export --example themed_signal_workspace --format snapshot
      mix unified_ui.export --module UnifiedUi.Examples.OperationsDashboard --format signals
      mix unified_ui.export --format coverage
  """

  alias UnifiedUi.Export

  @impl Mix.Task
  def run(args) do
    {opts, _positional, _invalid} =
      OptionParser.parse(args, strict: [example: :string, module: :string, format: :string])

    format =
      opts
      |> Keyword.get(:format, "inspection")
      |> parse_format()

    output =
      cond do
        format == :coverage ->
          case Export.coverage() do
            {:ok, text} -> text
          end

        example = Keyword.get(opts, :example) ->
          case Export.example(String.to_existing_atom(example), format) do
            {:ok, text} -> text
            :error -> Mix.raise("unknown example #{inspect(example)}")
          end

        module_name = Keyword.get(opts, :module) ->
          case Export.module(parse_module(module_name), format) do
            {:ok, text} -> text
            {:error, diagnostics} -> Mix.raise(diagnostics.message)
          end

        true ->
          Mix.raise(
            "usage: mix unified_ui.export --example ID [--format inspection|snapshot|signals|summary|diagnostics] | --module MODULE [--format inspection|snapshot|signals|summary|diagnostics] | --format coverage"
          )
      end

    Mix.shell().info(output)
  end

  defp parse_format("inspection"), do: :inspection
  defp parse_format("snapshot"), do: :snapshot
  defp parse_format("signals"), do: :signals
  defp parse_format("summary"), do: :summary
  defp parse_format("diagnostics"), do: :diagnostics
  defp parse_format("coverage"), do: :coverage

  defp parse_format(other) do
    Mix.raise("unsupported export format #{inspect(other)}")
  end

  defp parse_module(name) do
    name
    |> String.split(".")
    |> Module.concat()
  end
end
