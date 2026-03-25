defmodule Mix.Tasks.UnifiedUi.Validate do
  use Mix.Task

  @shortdoc "Runs the UnifiedUi validation and release-readiness workflow"

  @moduledoc """
  Runs the `UnifiedUi` validation workflow and prints the result.

      mix unified_ui.validate
      mix unified_ui.validate --format report
      mix unified_ui.validate --strict
  """

  alias UnifiedUi.Tooling

  @impl Mix.Task
  def run(args) do
    {opts, _positional, _invalid} =
      OptionParser.parse(args, strict: [format: :string, strict: :boolean])

    format = Keyword.get(opts, :format, "summary")
    strict? = Keyword.get(opts, :strict, false)
    report = Tooling.validation_report()

    output =
      case format do
        "summary" ->
          Tooling.validation_summary(report)

        "report" ->
          inspect(report, pretty: true, width: 100, limit: :infinity, sort_maps: true)

        other ->
          Mix.raise("unsupported validate format #{inspect(other)}")
      end

    Mix.shell().info(output)

    if strict? and not report.release_readiness.ready? do
      Mix.raise("UnifiedUi validation failed strict release-readiness gates")
    end
  end
end
