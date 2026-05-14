defmodule Mix.Tasks.DesktopUi.Build do
  use Mix.Task

  @shortdoc "Stages a desktop_ui target build directory"

  @moduledoc """
  Stages a deterministic `desktop_ui` target build directory.

      mix desktop_ui.build --target linux --dry-run
      mix desktop_ui.build --target macos
  """

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _positional, _invalid} =
      OptionParser.parse(args, switches: [target: :string, dry_run: :boolean, format: :string])

    target = parse_target(Keyword.get(opts, :target))
    format = Keyword.get(opts, :format, "summary")

    result =
      if opts[:dry_run] do
        DesktopUi.Build.build_plan(target)
      else
        case DesktopUi.Build.build(target) do
          {:ok, plan} -> plan
          {:error, reason} -> Mix.raise("desktop_ui build failed: #{inspect(reason)}")
        end
      end

    Mix.shell().info(format_output(result, format))
  end

  defp format_output(result, "summary") do
    summary = DesktopUi.Build.build_summary(result)

    [
      "DesktopUi build summary",
      "  target: #{summary.target}",
      "  stage root: #{summary.stage_root}",
      "  bundle mode: #{summary.bundle_mode}",
      "  runtime mode: #{summary.runtime_mode}",
      "  compiled host included?: #{summary.compiled_host_included?}",
      "  text native backend ready?: #{summary.text_native_backend_ready?}",
      "  image native backend ready?: #{summary.image_native_backend_ready?}"
    ]
    |> Enum.join("\n")
  end

  defp format_output(result, "report") do
    inspect(result, pretty: true, width: 100, limit: :infinity, sort_maps: true)
  end

  defp format_output(_result, other) do
    Mix.raise("unsupported build format #{inspect(other)}")
  end

  defp parse_target(nil) do
    Mix.raise(
      "usage: mix desktop_ui.build --target windows|macos|linux [--dry-run] [--format summary|report]"
    )
  end

  defp parse_target("windows"), do: :windows
  defp parse_target("macos"), do: :macos
  defp parse_target("linux"), do: :linux
  defp parse_target(other), do: Mix.raise("unsupported build target #{inspect(other)}")
end
