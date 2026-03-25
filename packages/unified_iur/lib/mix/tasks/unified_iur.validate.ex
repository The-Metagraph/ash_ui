defmodule Mix.Tasks.UnifiedIur.Validate do
  use Mix.Task

  @shortdoc "Runs the canonical UnifiedIUR validation workflow"

  @moduledoc """
  Runs the canonical `UnifiedIUR` validation workflow and prints the result.

      mix unified_iur.validate
      mix unified_iur.validate --format report
      mix unified_iur.validate --strict
  """

  alias UnifiedIUR.Tooling

  @impl Mix.Task
  def run(args) do
    {opts, _positional, _invalid} =
      OptionParser.parse(args, switches: [format: :string, strict: :boolean])

    format = Keyword.get(opts, :format, "summary")
    strict? = Keyword.get(opts, :strict, false)
    report = Tooling.validation_report()

    output =
      case format do
        "summary" ->
          Tooling.validation_summary(report)

        "report" ->
          Kernel.inspect(report, pretty: true, width: 100, limit: :infinity, sort_maps: true)

        other ->
          Mix.raise("unsupported validate format #{inspect(other)}")
      end

    Mix.shell().info(output)

    if strict? and not report.release_readiness.ready? do
      Mix.raise("UnifiedIUR validation failed strict release-readiness gates")
    end
  end
end
