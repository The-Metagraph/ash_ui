defmodule Mix.Tasks.ElmUi.Validate do
  use Mix.Task

  @shortdoc "Runs the maintained elm_ui validation workflow"

  @moduledoc """
  Runs the maintained `elm_ui` validation workflow and prints the result.

      mix elm_ui.validate
      mix elm_ui.validate --format report
      mix elm_ui.validate --strict
  """

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _positional, _invalid} =
      OptionParser.parse(args, switches: [format: :string, strict: :boolean])

    format = Keyword.get(opts, :format, "summary")
    strict? = Keyword.get(opts, :strict, false)
    report = ElmUi.Validate.validation_report()

    output =
      case format do
        "summary" ->
          ElmUi.Validate.validation_summary(report)

        "report" ->
          Kernel.inspect(report, pretty: true, width: 100, limit: :infinity, sort_maps: true)

        other ->
          Mix.raise("unsupported validate format #{inspect(other)}")
      end

    Mix.shell().info(output)

    if strict? do
      case ElmUi.Validate.release_readiness(:strict) do
        {:ok, _release} ->
          :ok

        {:error, _release} ->
          Mix.raise("ElmUi validation failed strict release-readiness gates")
      end
    end
  end
end
