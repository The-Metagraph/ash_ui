defmodule Mix.Tasks.AshUi.Examples.Start do
  @moduledoc """
  Launches one checked-in example app from the root project.

  The maintained workflow delegates into the target example directory and runs
  its local `mix example.start` alias. Use `--dry-run` to confirm the command
  and review profile without starting the Phoenix server.
  """

  use Mix.Task

  alias AshUI.Examples.Suite

  @shortdoc "Launch one checked-in example app from the root project"

  @switches [actor: :string, dry_run: :boolean, runtime: :string, seed: :string]

  @impl Mix.Task
  def run(args) do
    {opts, positional} = OptionParser.parse!(args, strict: @switches)
    directory = parse_directory!(positional)
    spec = Suite.launch_spec(directory, opts)

    Mix.shell().info("#{spec.title} (`#{spec.directory}`)")
    Mix.shell().info("Project path: #{spec.project_path}")
    Mix.shell().info("Shell: #{spec.shell}")

    Mix.shell().info(
      "Review profile: actor=#{spec.actor} seed=#{spec.seed} runtime=#{spec.runtime}"
    )

    Mix.shell().info("Meaningful Interaction Story: #{spec.story_text}")
    Mix.shell().info("Canonical Signal Preview: #{spec.signal_text}")

    if spec.support_notice do
      Mix.shell().info("Support notice: #{spec.support_notice}")
    end

    if Keyword.get(opts, :dry_run, false) do
      Mix.shell().info("Dry run: #{spec.dry_run_command}")
    else
      {_, status} =
        System.cmd(
          "mix",
          ["example.start"],
          cd: spec.project_path,
          env: [{"MIX_ENV", "dev"}],
          into: IO.stream(:stdio, :line),
          stderr_to_stdout: true
        )

      if status != 0 do
        Mix.raise("example app failed to start for #{directory}")
      end
    end
  end

  defp parse_directory!([directory]), do: directory

  defp parse_directory!(_args) do
    Mix.raise("expected exactly one example directory, e.g. `mix ash_ui.examples.start button`")
  end
end
