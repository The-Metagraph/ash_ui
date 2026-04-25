defmodule Mix.Tasks.AshUi.Examples.Preview do
  @moduledoc """
  Prints the maintained review surface for one checked-in example app.
  """

  use Mix.Task

  alias AshUI.Examples.Suite

  @shortdoc "Show the maintained review surface for one example app"

  @switches [actor: :string, seed: :string, runtime: :string]

  @impl Mix.Task
  def run(args) do
    {opts, positional} = OptionParser.parse!(args, strict: @switches)
    directory = parse_directory!(positional)
    spec = Suite.preview_spec(directory, opts)

    Mix.shell().info("#{spec.title} (`#{spec.directory}`)")
    Mix.shell().info("Shell: #{spec.shell}")
    Mix.shell().info("Canonical subject: #{spec.canonical_subject}")
    Mix.shell().info("Parity: #{spec.parity_kind}")
    Mix.shell().info("Runtime: #{spec.maintained_runtime}")

    Mix.shell().info(
      "Review profile: actor=#{spec.actor} seed=#{spec.seed} runtime=#{spec.runtime}"
    )

    Mix.shell().info("Meaningful Interaction Story: #{spec.story_text}")
    Mix.shell().info("Canonical Signal Preview: #{spec.signal_text}")

    if spec.support_notice do
      Mix.shell().info("Support notice: #{spec.support_notice}")
    end
  end

  defp parse_directory!([directory]), do: directory

  defp parse_directory!(_args) do
    Mix.raise("expected exactly one example directory, e.g. `mix ash_ui.examples.preview button`")
  end
end
