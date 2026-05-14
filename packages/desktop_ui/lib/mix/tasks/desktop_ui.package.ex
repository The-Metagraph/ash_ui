defmodule Mix.Tasks.DesktopUi.Package do
  use Mix.Task

  @shortdoc "Packages a desktop_ui target artifact"

  @moduledoc """
  Packages a deterministic `desktop_ui` target artifact.

      mix desktop_ui.package --target linux --dry-run
      mix desktop_ui.package --target macos
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
        DesktopUi.Package.package_plan(target)
      else
        case DesktopUi.Package.package(target) do
          {:ok, plan} -> plan
          {:error, reason} -> Mix.raise("desktop_ui package failed: #{inspect(reason)}")
        end
      end

    Mix.shell().info(format_output(result, format))
  end

  defp format_output(result, "summary") do
    summary = DesktopUi.Package.package_summary(result)
    warnings = Enum.map_join(summary.warnings, ", ", &Atom.to_string/1)

    [
      "DesktopUi package summary",
      "  target: #{summary.target}",
      "  target root: #{summary.target_root}",
      "  archive path: #{summary.archive_path}",
      "  bundle path: #{summary.bundle_path || "n/a"}",
      "  payload root: #{summary.payload_root || "n/a"}",
      "  compiled host included?: #{summary.compiled_host_included?}",
      "  fallback review only?: #{summary.fallback_review_only?}",
      "  warnings: #{if(warnings == "", do: "none", else: warnings)}"
    ]
    |> Enum.join("\n")
  end

  defp format_output(result, "report") do
    inspect(result, pretty: true, width: 100, limit: :infinity, sort_maps: true)
  end

  defp format_output(_result, other) do
    Mix.raise("unsupported package format #{inspect(other)}")
  end

  defp parse_target(nil) do
    Mix.raise(
      "usage: mix desktop_ui.package --target windows|macos|linux [--dry-run] [--format summary|report]"
    )
  end

  defp parse_target("windows"), do: :windows
  defp parse_target("macos"), do: :macos
  defp parse_target("linux"), do: :linux
  defp parse_target(other), do: Mix.raise("unsupported package target #{inspect(other)}")
end
