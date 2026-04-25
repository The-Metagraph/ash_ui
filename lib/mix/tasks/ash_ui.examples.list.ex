defmodule Mix.Tasks.AshUi.Examples.List do
  @moduledoc """
  Lists the maintained Ash UI example-suite entries from the root project.
  """

  use Mix.Task

  alias AshUI.Examples.Suite

  @shortdoc "List the maintained Ash UI example-suite entries"

  @impl Mix.Task
  def run(_args) do
    Mix.shell().info("Ash UI Example Suite")
    Mix.shell().info("Directory | Family | Phase | Parity | Root launcher")

    Enum.each(Suite.catalog_entries(), fn entry ->
      Mix.shell().info(
        "#{entry.directory} | #{entry.family} | #{entry.phase} | #{entry.parity_kind} | mix ash_ui.examples.start #{entry.directory}"
      )
    end)
  end
end
