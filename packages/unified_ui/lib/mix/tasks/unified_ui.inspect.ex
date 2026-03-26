defmodule Mix.Tasks.UnifiedUi.Inspect do
  use Mix.Task

  @shortdoc "Prints maintainer-facing inspection output for UnifiedUi examples or modules"

  @moduledoc """
  Prints maintainer-facing inspection output for `UnifiedUi` examples or modules.

      mix unified_ui.inspect --example foundational_screen
      mix unified_ui.inspect --example themed_signal_workspace --format signals
      mix unified_ui.inspect --module UnifiedUi.Examples.OperationsDashboard
      mix unified_ui.inspect --coverage
  """

  alias UnifiedUi.Tooling

  @impl Mix.Task
  def run(args) do
    {opts, _positional, _invalid} =
      OptionParser.parse(args,
        strict: [example: :string, module: :string, format: :string, coverage: :boolean]
      )

    if Keyword.get(opts, :coverage, false) do
      Mix.shell().info(Tooling.coverage_summary())
    else
      format = Keyword.get(opts, :format, "report")

      output =
        cond do
          example = Keyword.get(opts, :example) ->
            example
            |> String.to_existing_atom()
            |> inspect_example(format)

          module_name = Keyword.get(opts, :module) ->
            module_name
            |> parse_module()
            |> inspect_module(format)

          true ->
            Mix.raise(
              "usage: mix unified_ui.inspect --example ID [--format report|signals|diagnostics] | --module MODULE [--format report|signals|diagnostics] | --coverage"
            )
        end

      Mix.shell().info(output)
    end
  end

  defp inspect_example(id, "report") do
    case Tooling.inspect_example(id) do
      {:ok, report} -> inspect_term(report)
      :error -> Mix.raise("unknown example #{inspect(id)}")
      {:error, diagnostics} -> Tooling.render_diagnostics(diagnostics)
    end
  end

  defp inspect_example(id, "signals") do
    case Tooling.inspect_example(id) do
      {:ok, report} -> inspect_term(report.signal_coverage)
      :error -> Mix.raise("unknown example #{inspect(id)}")
      {:error, diagnostics} -> Tooling.render_diagnostics(diagnostics)
    end
  end

  defp inspect_example(id, "diagnostics") do
    case Tooling.inspect_example(id) do
      {:ok, report} ->
        report.module
        |> Tooling.module_diagnostics()
        |> Tooling.render_diagnostics()

      :error ->
        Mix.raise("unknown example #{inspect(id)}")

      {:error, diagnostics} ->
        Tooling.render_diagnostics(diagnostics)
    end
  end

  defp inspect_example(_id, other) do
    Mix.raise("unsupported inspect format #{inspect(other)}")
  end

  defp inspect_module(module, "report") do
    case Tooling.inspect_module(module) do
      {:ok, report} -> inspect_term(report)
      {:error, diagnostics} -> Tooling.render_diagnostics(diagnostics)
    end
  end

  defp inspect_module(module, "signals") do
    case Tooling.inspect_module(module) do
      {:ok, report} -> inspect_term(report.signal_coverage)
      {:error, diagnostics} -> Tooling.render_diagnostics(diagnostics)
    end
  end

  defp inspect_module(module, "diagnostics") do
    module
    |> Tooling.module_diagnostics()
    |> Tooling.render_diagnostics()
  end

  defp inspect_module(_module, other) do
    Mix.raise("unsupported inspect format #{inspect(other)}")
  end

  defp parse_module(name) do
    name
    |> String.split(".")
    |> Module.concat()
  end

  defp inspect_term(term) do
    inspect(term, pretty: true, width: 100, limit: :infinity, sort_maps: true)
  end
end
