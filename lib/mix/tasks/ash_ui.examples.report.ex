defmodule Mix.Tasks.AshUi.Examples.Report do
  @moduledoc """
  Prints the maintained Phase 21 example-suite review report.
  """

  use Mix.Task

  alias AshUI.Examples.Suite

  @shortdoc "Print the Ash UI example-suite review report"

  @impl Mix.Task
  @doc """
  Prints the maintained Phase 21 example-suite report.
  """
  def run(_args) do
    Mix.shell().info(Suite.render_suite_report())
  end
end
