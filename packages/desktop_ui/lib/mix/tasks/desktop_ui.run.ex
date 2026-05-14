defmodule Mix.Tasks.DesktopUi.Run do
  use Mix.Task

  @shortdoc "Runs a desktop_ui example through the visible SDL3 or fallback host path"

  @moduledoc """
  Runs a maintained `desktop_ui` example through the visible SDL3 or fallback
  host execution path and prints the execution diagnostics.

      mix desktop_ui.run --format catalog
      mix desktop_ui.run native_foundational
      mix desktop_ui.run canonical_foundational --format report
      mix desktop_ui.run native_foundational --backend compiled --linger-ms 3000
  """

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, positional, _invalid} =
      OptionParser.parse(args,
        switches: [format: :string, backend: :string, linger_ms: :integer]
      )

    format = Keyword.get(opts, :format, "summary")
    backend = parse_backend(Keyword.get(opts, :backend, "auto"))
    linger_ms = Keyword.get(opts, :linger_ms, 1_500)

    case {format, positional} do
      {"catalog", _} ->
        Mix.shell().info(
          Kernel.inspect(DesktopUi.Tooling.run_catalog(),
            pretty: true,
            width: 100,
            limit: :infinity,
            sort_maps: true
          )
        )

      {chosen_format, [example_id]} ->
        case DesktopUi.Tooling.run_example(example_id, backend: backend, linger_ms: linger_ms) do
          {:ok, execution} ->
            Mix.shell().info(format_execution(execution, chosen_format))

          {:error, reason} ->
            Mix.raise("unable to run example #{inspect(example_id)}: #{inspect(reason)}")
        end

      _ ->
        Mix.raise(
          "usage: mix desktop_ui.run [EXAMPLE_ID] [--format summary|report|catalog] [--backend auto|compiled|fallback] [--linger-ms 1500]"
        )
    end
  end

  defp format_execution(execution, "summary") do
    [
      "DesktopUi run summary",
      "  example: #{execution.id}",
      "  category: #{execution.metadata.category}",
      "  execution mode: #{execution.execution_mode}",
      "  backend: #{execution.backend}",
      "  visible window?: #{execution.visible_window?}",
      "  presented frame?: #{execution.presented_frame?}",
      "  fallback used?: #{execution.fallback_used?}",
      "  renderer completeness: #{renderer_completeness(execution)}",
      "  interactive visible execution?: #{execution.execution_mode == :visible_window}",
      "  interaction events observed: #{interaction_event_count(execution)}",
      "  visible runner ready?: #{execution.capabilities.build.visible_runner_ready?}",
      "  protocol launch ready?: #{execution.capabilities.build.launch_ready?}",
      "  native text mode: #{execution.resource_support.text.active_mode}",
      "  native image mode: #{execution.resource_support.images.active_mode}"
    ]
    |> Enum.join("\n")
  end

  defp format_execution(execution, "report") do
    Kernel.inspect(execution, pretty: true, width: 100, limit: :infinity, sort_maps: true)
  end

  defp format_execution(_execution, other) do
    Mix.raise("unsupported run format #{inspect(other)}")
  end

  defp parse_backend("auto"), do: :auto
  defp parse_backend("compiled"), do: :compiled
  defp parse_backend("fallback"), do: :fallback
  defp parse_backend(other), do: Mix.raise("unsupported run backend #{inspect(other)}")

  defp renderer_completeness(%{execution_mode: :visible_window}), do: :widget_complete_interactive
  defp renderer_completeness(_execution), do: :bounded_fallback_review

  defp interaction_event_count(%{details: %{interaction_summary: %{"total_events" => total}}})
       when is_integer(total),
       do: total

  defp interaction_event_count(_execution), do: 0
end
