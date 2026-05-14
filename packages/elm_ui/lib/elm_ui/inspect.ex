defmodule ElmUi.Inspect do
  @moduledoc """
  Maintainer-facing preview and inspection workflows for `elm_ui` examples.
  """

  @spec preview(atom() | String.t()) :: {:ok, map()} | {:error, :unknown_example}
  def preview(id) do
    with {:ok, metadata} <- fetch_metadata(id) do
      {:ok,
       %{
         id: metadata.id,
         metadata: metadata,
         surface: preview_surface(metadata)
       }}
    end
  end

  @spec catalog() :: map()
  def catalog do
    %{
      examples: ElmUi.Examples.catalog(),
      preview_surfaces: ElmUi.Tooling.preview_surfaces(),
      package_overview: ElmUi.Inspection.package_overview()
    }
  end

  @spec runtime(atom() | String.t()) :: {:ok, map()} | {:error, :unknown_example}
  def runtime(id) do
    with {:ok, preview} <- preview(id) do
      {:ok, preview.surface}
    end
  end

  @spec render(atom() | String.t(), atom()) :: {:ok, String.t()} | {:error, :unknown_example}
  def render(id, format \\ :report) do
    with {:ok, preview} <- preview(id) do
      {:ok, format_preview(preview, format)}
    end
  end

  defp preview_surface(%{category: :native, id: :native_counter}) do
    preview_native(ElmUi.Examples.native_counter_screen(), %{})
  end

  defp preview_surface(%{category: :native, id: :native_foundational}) do
    preview_native(ElmUi.Examples.native_foundational_screen(), %{})
  end

  defp preview_surface(%{category: :native, id: :native_transport}) do
    preview_native(ElmUi.Examples.native_transport_screen(), %{})
  end

  defp preview_surface(%{category: :native, id: :native_navigation}) do
    preview_native(ElmUi.Examples.native_navigation_screen(), %{})
  end

  defp preview_surface(%{category: :native, id: :native_advanced}) do
    preview_native(ElmUi.Examples.native_advanced_screen(), %{})
  end

  defp preview_surface(%{category: :native, id: :native_styling}) do
    preview_native(
      ElmUi.Examples.native_styling_screen(),
      %{focused_id: "style-query", editing_ids: ["style-query"]}
    )
  end

  defp preview_surface(%{category: :canonical, id: :canonical_welcome}) do
    preview_canonical(ElmUi.Examples.canonical_welcome_screen(), %{})
  end

  defp preview_surface(%{category: :canonical, id: :canonical_foundational}) do
    preview_canonical(ElmUi.Examples.canonical_foundational_screen(), %{})
  end

  defp preview_surface(%{category: :canonical, id: :canonical_transport}) do
    preview_canonical(ElmUi.Examples.canonical_transport_screen(), %{})
  end

  defp preview_surface(%{category: :canonical, id: :canonical_navigation}) do
    preview_canonical(ElmUi.Examples.canonical_navigation_screen(), %{})
  end

  defp preview_surface(%{category: :canonical, id: :canonical_advanced}) do
    preview_canonical(ElmUi.Examples.canonical_advanced_screen(), %{})
  end

  defp preview_surface(%{category: :canonical, id: :canonical_styling}) do
    preview_canonical(
      ElmUi.Examples.canonical_styling_screen(),
      %{theme: :midnight, focused_id: "style-query", editing_ids: ["style-query"]}
    )
  end

  defp preview_surface(%{category: :mixed, id: :foundational_continuity}) do
    ElmUi.Examples.foundational_comparison()
  end

  defp preview_surface(%{category: :mixed, id: :advanced_continuity}) do
    ElmUi.Examples.advanced_comparison()
  end

  defp preview_surface(%{category: :mixed, id: :mixed_transport}) do
    ElmUi.Examples.mixed_transport_comparison()
  end

  defp preview_surface(%{category: :mixed, id: :navigation_continuity}) do
    ElmUi.Examples.navigation_comparison()
  end

  defp preview_surface(%{category: :mixed, id: :styling_continuity}) do
    ElmUi.Examples.styling_comparison()
  end

  defp preview_native(screen, local_state) do
    {:ok, state} = ElmUi.Runtime.mount_native_screen(screen)
    {:ok, snapshot} = ElmUi.Inspection.runtime_snapshot(state, local_state)
    snapshot
  end

  defp preview_canonical(element, opts) do
    {runtime_opts, local_state} = split_preview_opts(opts)
    {:ok, state} = ElmUi.Runtime.mount_iur_screen(element, runtime_opts)
    {:ok, snapshot} = ElmUi.Inspection.runtime_snapshot(state, local_state)
    snapshot
  end

  defp split_preview_opts(opts) do
    local_state = Map.take(opts, [:focused_id, :editing_ids])
    runtime_opts = Keyword.take(Enum.into(opts, []), [:theme])
    {runtime_opts, local_state}
  end

  defp fetch_metadata(id) do
    case resolve_metadata(id) do
      nil -> {:error, :unknown_example}
      metadata -> {:ok, metadata}
    end
  end

  defp resolve_metadata(id) when is_atom(id), do: ElmUi.Examples.metadata(id)

  defp resolve_metadata(id) when is_binary(id) do
    Enum.find(ElmUi.Examples.catalog(), &(Atom.to_string(&1.id) == id))
  end

  defp resolve_metadata(_id), do: nil

  defp format_preview(preview, :report) do
    Kernel.inspect(preview, pretty: true, width: 100, limit: :infinity, sort_maps: true)
  end

  defp format_preview(preview, :metadata) do
    Kernel.inspect(preview.metadata, pretty: true, width: 100, limit: :infinity, sort_maps: true)
  end

  defp format_preview(preview, :comparison) do
    payload =
      case preview.metadata.category do
        :mixed ->
          %{
            id: preview.id,
            metadata: preview.metadata,
            surface: preview.surface
          }

        _other ->
          %{
            id: preview.id,
            metadata: preview.metadata,
            direct_native_and_canonical_runtime_behavior: preview.surface
          }
      end

    Kernel.inspect(payload, pretty: true, width: 100, limit: :infinity, sort_maps: true)
  end

  defp format_preview(preview, :diagnostics) do
    diagnostics =
      case preview.metadata.category do
        :mixed ->
          %{
            id: preview.id,
            category: preview.metadata.category,
            continuity: Map.get(preview.surface, :continuity, %{}),
            review_artifact: Map.get(preview.surface, :review_artifact, %{}),
            tooling_workflows: ElmUi.Tooling.workflows()
          }

        _other ->
          %{
            id: preview.id,
            category: preview.metadata.category,
            runtime: Map.get(preview.surface, :runtime, %{}),
            server: Map.get(preview.surface, :server, %{}),
            frontend: Map.get(preview.surface, :frontend, %{}),
            transport_modes: ElmUi.Transport.modes()
          }
      end

    Kernel.inspect(diagnostics, pretty: true, width: 100, limit: :infinity, sort_maps: true)
  end
end
