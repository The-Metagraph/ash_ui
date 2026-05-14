defmodule LiveUi.Export do
  @moduledoc """
  Review-friendly export helpers for maintained `live_ui` examples.
  """

  alias LiveUi.{Examples, Tooling}

  @type export_format ::
          :catalog | :metadata | :report | :html | :comparison | :diagnostics | :style | :artifact

  @spec catalog() :: String.t()
  def catalog do
    inspect_output(Examples.catalog())
  end

  @spec example(atom() | String.t(), export_format()) :: {:ok, String.t()} | {:error, term()}
  def example(id, format \\ :report) do
    with {:ok, example} <- resolve_example(id) do
      export(example, format)
    end
  end

  defp export(_example, :catalog), do: {:ok, catalog()}

  defp export(example, :metadata) do
    {:ok, inspect_output(example)}
  end

  defp export(example, :report) do
    with {:ok, inspection} <- Tooling.inspect_example(example.id) do
      {:ok, inspect_output(inspection)}
    end
  end

  defp export(example, :html) do
    with {:ok, inspection} <- Tooling.preview_example(example.id),
         {:ok, html} <- html_from_preview(inspection) do
      {:ok, html}
    end
  end

  defp export(example, :comparison) do
    exporter =
      case example.path do
        :mixed -> Tooling.inspect_example(example.id)
        _other -> Tooling.compare_example_pair(example.id)
      end

    with {:ok, output} <- exporter do
      {:ok, inspect_output(output)}
    end
  end

  defp export(example, :style) do
    exporter =
      case example.path do
        :mixed -> Tooling.inspect_example(example.id)
        _other -> Tooling.compare_example_pair(example.id)
      end

    with {:ok, output} <- exporter do
      {:ok, inspect_output(style_output(output))}
    end
  end

  defp export(example, :artifact) do
    exporter =
      case example.path do
        :mixed -> Tooling.inspect_example(example.id)
        _other -> Tooling.compare_example_pair(example.id)
      end

    with {:ok, output} <- exporter,
         {:ok, artifact} <- artifact_output(output) do
      {:ok, inspect_output(artifact)}
    end
  end

  defp export(example, :diagnostics) do
    exporter =
      case example.path do
        :mixed ->
          Tooling.inspect_example(example.id)

        _other ->
          Tooling.compare_example_pair(example.id)
      end

    with {:ok, output} <- exporter do
      {:ok, inspect_output(diagnostics_output(output))}
    end
  end

  defp diagnostics_output(%{diagnostics: diagnostics} = output) when is_list(diagnostics) do
    %{
      example: Map.get(output, :example),
      native_example: Map.get(output, :native_example),
      canonical_example: Map.get(output, :canonical_example),
      browser_style: get_in(output, [:report, :browser_style]),
      native_browser_style: get_in(output, [:report, :native, :browser_style]),
      canonical_browser_style: get_in(output, [:report, :canonical, :browser_style]),
      diagnostics: diagnostics
    }
  end

  defp diagnostics_output(%{result: result, example: example}) when is_map(result) do
    %{
      example: example,
      diagnostics:
        %{}
        |> maybe_put(:diagnostics, Map.get(result, :diagnostics))
        |> maybe_put(:browser_style, Map.get(result, :browser_style))
        |> maybe_put(:browser_style_nodes, Map.get(result, :browser_style_nodes))
        |> maybe_put(:runtime_action, get_in(result, [:boundary, :runtime_action]))
        |> maybe_put(:native_boundary, get_in(result, [:boundary, :native_boundary]))
        |> maybe_put(:canonical_boundary, get_in(result, [:boundary, :canonical_boundary]))
        |> maybe_put(:profile_diagnostics, get_in(result, [:profile, :diagnostics]))
        |> maybe_put(:operations_diagnostics, get_in(result, [:operations, :diagnostics]))
    }
  end

  defp html_from_preview(%{result: %{html: html}}) when is_binary(html), do: {:ok, html}
  defp html_from_preview(_preview), do: {:error, :html_not_available}

  defp style_output(%{example: example, result: %{browser_style: _browser_style} = result}) do
    %{
      example: example,
      path: Map.get(result, :path),
      screen: Map.get(result, :screen),
      browser_style: Map.get(result, :browser_style),
      browser_style_nodes: Map.get(result, :browser_style_nodes, [])
    }
  end

  defp style_output(%{
         example: example,
         native_example: native_example,
         canonical_example: canonical_example,
         report: report
       }) do
    %{
      example: example,
      native_example: native_example,
      canonical_example: canonical_example,
      browser_style: Map.get(report, :browser_style),
      native_browser_style: get_in(report, [:native, :browser_style]),
      native_browser_style_nodes: get_in(report, [:native, :browser_style_nodes]),
      canonical_browser_style: get_in(report, [:canonical, :browser_style]),
      canonical_browser_style_nodes: get_in(report, [:canonical, :browser_style_nodes]),
      diagnostics: Map.get(report, :diagnostics, [])
    }
  end

  defp style_output(%{example: example, result: result}) when is_map(result) do
    %{
      example: example,
      style_sections: collect_style_sections(result)
    }
  end

  defp artifact_output(%{example: example, result: %{html: html} = result})
       when is_binary(html) do
    {:ok,
     %{
       example: example,
       path: Map.get(result, :path),
       screen: Map.get(result, :screen),
       html: html,
       browser_style: Map.get(result, :browser_style),
       browser_style_nodes: Map.get(result, :browser_style_nodes, [])
     }}
  end

  defp artifact_output(%{
         example: example,
         native_example: native_example,
         canonical_example: canonical_example,
         report: report
       }) do
    {:ok,
     %{
       example: example,
       native_example: native_example,
       canonical_example: canonical_example,
       native: artifact_snapshot(Map.get(report, :native)),
       canonical: artifact_snapshot(Map.get(report, :canonical)),
       browser_style: Map.get(report, :browser_style),
       diagnostics: Map.get(report, :diagnostics, [])
     }}
  end

  defp artifact_output(_output), do: {:error, :artifact_not_available}

  defp artifact_snapshot(%{html: html} = snapshot) when is_binary(html) do
    %{
      path: Map.get(snapshot, :path),
      screen: Map.get(snapshot, :screen),
      html: html,
      browser_style: Map.get(snapshot, :browser_style),
      browser_style_nodes: Map.get(snapshot, :browser_style_nodes, [])
    }
  end

  defp artifact_snapshot(_snapshot), do: nil

  defp collect_style_sections(result) when is_map(result) do
    result
    |> Enum.reduce(%{}, fn {key, value}, sections ->
      case style_section(value) do
        nil -> sections
        section -> Map.put(sections, key, section)
      end
    end)
  end

  defp style_section(%{browser_style: _browser_style} = snapshot) do
    %{
      browser_style: Map.get(snapshot, :browser_style),
      browser_style_nodes: Map.get(snapshot, :browser_style_nodes, [])
    }
  end

  defp style_section(%{report: report} = output) when is_map(report) do
    style_output(output)
  end

  defp style_section(_value), do: nil

  defp resolve_example(id) do
    case Examples.find(id) do
      {:ok, example} -> {:ok, example}
      :error -> {:error, :unknown_example}
    end
  end

  defp inspect_output(value) do
    Kernel.inspect(value, pretty: true, width: 100, limit: :infinity, sort_maps: true)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
