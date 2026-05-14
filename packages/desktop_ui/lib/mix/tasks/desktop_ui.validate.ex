defmodule Mix.Tasks.DesktopUi.Validate do
  use Mix.Task

  @shortdoc "Runs the maintained desktop_ui validation workflow"

  @moduledoc """
  Runs the maintained `desktop_ui` validation workflow and prints the result.

      mix desktop_ui.validate
      mix desktop_ui.validate --format report
      mix desktop_ui.validate --strict
  """

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _positional, _invalid} =
      OptionParser.parse(args, switches: [format: :string, strict: :boolean])

    format = Keyword.get(opts, :format, "summary")
    strict? = Keyword.get(opts, :strict, false)
    report = DesktopUi.Validate.validation_report()

    output =
      case format do
        "summary" ->
          DesktopUi.Validate.validation_summary(report)

        "report" ->
          Kernel.inspect(report, pretty: true, width: 100, limit: :infinity, sort_maps: true)

        other ->
          Mix.raise("unsupported validate format #{inspect(other)}")
      end

    Mix.shell().info(output)

    if strict? do
      case DesktopUi.Validate.release_readiness(:strict) do
        {:ok, _release} ->
          :ok

        {:error, _release} ->
          Mix.raise("DesktopUi validation failed strict release-readiness gates")
      end
    end
  end
end
