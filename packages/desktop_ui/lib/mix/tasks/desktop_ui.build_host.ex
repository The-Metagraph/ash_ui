defmodule Mix.Tasks.DesktopUi.BuildHost do
  use Mix.Task

  @shortdoc "Builds the optional compiled SDL3 native host for desktop_ui"

  @moduledoc """
  Builds the optional compiled SDL3 host for `desktop_ui`.

      mix desktop_ui.build_host
      mix desktop_ui.build_host --dry-run
  """

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")
    {opts, _positional, _invalid} = OptionParser.parse(args, switches: [dry_run: :boolean])

    capabilities = DesktopUi.Sdl3.Capabilities.detect()
    compile_plan = DesktopUi.Sdl3.NativeBuild.compile_plan(capabilities: capabilities)

    if opts[:dry_run] do
      Mix.shell().info(
        Kernel.inspect(
          %{
            capabilities: capabilities,
            compile_plan: compile_plan
          },
          pretty: true,
          width: 100,
          limit: :infinity,
          sort_maps: true
        )
      )
    else
      ensure_buildable!(capabilities)
      File.mkdir_p!(compile_plan.output_root)

      {output, status} =
        System.cmd(compile_plan.compiler, compile_plan.args, stderr_to_stdout: true)

      if output != "" do
        Mix.shell().info(output)
      end

      if status != 0 do
        Mix.raise("desktop_ui SDL3 native host build failed with exit status #{status}")
      end

      Mix.shell().info("Built #{compile_plan.executable}")

      probe =
        case System.cmd(compile_plan.executable, ["--probe"], stderr_to_stdout: true) do
          {probe_output, 0} -> String.trim(probe_output)
          _other -> "probe_failed"
        end

      Mix.shell().info("Probe: #{probe}")
    end
  end

  defp ensure_buildable!(capabilities) do
    if capabilities.build.buildable? do
      :ok
    else
      Mix.raise(
        "desktop_ui SDL3 native host is not buildable on this machine: " <>
          inspect(capabilities.build, pretty: true, limit: :infinity)
      )
    end
  end
end
