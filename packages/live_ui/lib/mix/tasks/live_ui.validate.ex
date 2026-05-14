defmodule Mix.Tasks.LiveUi.Validate do
  use Mix.Task

  @shortdoc "Runs the maintained live_ui validation workflow"

  @moduledoc """
  Runs the maintained `live_ui` validation workflow and prints the result.

      mix live_ui.validate
      mix live_ui.validate --format report
      mix live_ui.validate --strict
  """

  alias LiveUi.Tooling

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
      Mix.raise("LiveUi validation failed strict release-readiness gates")
    end
  end
end
