defmodule Mix.Tasks.AshUi.Examples.Validate do
  @moduledoc """
  Runs the maintained example-suite validations from the root project.
  """

  use Mix.Task

  alias AshUI.Examples.Suite

  @shortdoc "Validate the checked-in Ash UI example suite"

  @impl Mix.Task
  @doc """
  Runs the maintained example-suite validations from the root project.
  """
  def run(_args) do
    case Suite.validate_suite() do
      :ok ->
        Mix.shell().info("Ash UI example suite validation passed.")

      {:error, {:suite_validation_failed, failures}} ->
        Enum.each(failures, fn failure ->
          Mix.shell().error("FAIL #{failure.check}: #{inspect(failure.reason)}")
        end)

        Mix.raise("Ash UI example suite validation failed.")
    end
  end
end
