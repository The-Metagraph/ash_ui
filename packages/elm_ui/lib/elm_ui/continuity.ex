defmodule ElmUi.Continuity do
  @moduledoc """
  Native-versus-canonical continuity diagnostics for `elm_ui`.
  """

  alias ElmUi.Inspection
  alias ElmUi.ServerRuntime.State

  @seams [
    :widget_identity,
    :server_theme_propagation,
    :server_style_resolution,
    :frontend_style_realization
  ]

  @diagnostic_kinds [
    :kind_mismatch,
    :theme_mismatch,
    :missing_theme,
    :resolved_style_mismatch,
    :frontend_realization_drift
  ]

  @spec seams() :: [atom()]
  def seams, do: @seams

  @spec diagnostic_kinds() :: [atom()]
  def diagnostic_kinds, do: @diagnostic_kinds

  @spec compare(State.t(), State.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def compare(%State{} = native_state, %State{} = canonical_state, opts \\ []) do
    native_local_state = Keyword.get(opts, :native_local_state, %{})
    canonical_local_state = Keyword.get(opts, :canonical_local_state, %{})

    with {:ok, native_snapshot} <- Inspection.runtime_snapshot(native_state, native_local_state),
         {:ok, canonical_snapshot} <-
           Inspection.runtime_snapshot(canonical_state, canonical_local_state) do
      {:ok, build_report(native_snapshot, canonical_snapshot)}
    end
  end

  @spec contract() :: map()
  def contract do
    %{
      seams: seams(),
      diagnostic_kinds: diagnostic_kinds(),
      validation: [:pass, :fail]
    }
  end

  defp build_report(native_snapshot, canonical_snapshot) do
    native_server_nodes = index_by_id(native_snapshot.server.style_nodes)
    canonical_server_nodes = index_by_id(canonical_snapshot.server.style_nodes)
    native_frontend_nodes = index_by_id(native_snapshot.frontend.style_nodes)
    canonical_frontend_nodes = index_by_id(canonical_snapshot.frontend.style_nodes)

    shared_ids =
      native_server_nodes
      |> Map.keys()
      |> Enum.filter(&Map.has_key?(canonical_server_nodes, &1))
      |> Enum.sort()

    diagnostics =
      shared_ids
      |> Enum.flat_map(fn id ->
        [
          widget_identity_diagnostic(id, native_server_nodes[id], canonical_server_nodes[id]),
          theme_diagnostic(id, native_server_nodes[id], canonical_server_nodes[id]),
          resolved_style_diagnostic(id, native_server_nodes[id], canonical_server_nodes[id]),
          frontend_realization_diagnostic(
            id,
            native_frontend_nodes[id],
            canonical_frontend_nodes[id]
          )
        ]
      end)
      |> Enum.reject(&is_nil/1)

    %{
      native: native_snapshot,
      canonical: canonical_snapshot,
      diagnostics: diagnostics,
      continuity: %{
        shared_ids: shared_ids,
        widget_identity_match?: no_reason?(diagnostics, :kind_mismatch),
        theme_propagation_match?:
          no_reason?(diagnostics, :theme_mismatch) and no_reason?(diagnostics, :missing_theme),
        style_resolution_match?: no_reason?(diagnostics, :resolved_style_mismatch),
        frontend_realization_match?: no_reason?(diagnostics, :frontend_realization_drift),
        validation: %{
          status: if(diagnostics == [], do: :pass, else: :fail),
          failing_seams: diagnostics |> Enum.map(& &1.seam) |> Enum.uniq() |> Enum.sort(),
          actionable_output: diagnostics
        }
      }
    }
  end

  defp widget_identity_diagnostic(id, native_node, canonical_node) do
    if native_node.kind == canonical_node.kind do
      nil
    else
      diagnostic(
        :widget_identity,
        :kind_mismatch,
        id,
        "Inspect ElmUi.Renderer for native/canonical widget identity drift",
        native_node.kind,
        canonical_node.kind
      )
    end
  end

  defp theme_diagnostic(id, native_node, canonical_node) do
    cond do
      is_nil(native_node.theme) or is_nil(canonical_node.theme) ->
        diagnostic(
          :server_theme_propagation,
          :missing_theme,
          id,
          "Inspect ElmUi.ServerRuntime.StyleResolver theme propagation into the render payload",
          native_node.theme,
          canonical_node.theme
        )

      native_node.theme == canonical_node.theme ->
        nil

      true ->
        diagnostic(
          :server_theme_propagation,
          :theme_mismatch,
          id,
          "Inspect ElmUi.ServerRuntime.StyleResolver and renderer theme defaults for propagation drift",
          native_node.theme,
          canonical_node.theme
        )
    end
  end

  defp resolved_style_diagnostic(id, native_node, canonical_node) do
    if native_node.resolved_styles == canonical_node.resolved_styles do
      nil
    else
      diagnostic(
        :server_style_resolution,
        :resolved_style_mismatch,
        id,
        "Inspect ElmUi.ServerRuntime.StyleResolver and canonical style mapping for resolved-style drift",
        native_node.resolved_styles,
        canonical_node.resolved_styles
      )
    end
  end

  defp frontend_realization_diagnostic(id, native_node, canonical_node) do
    native_projection = %{
      behavior: native_node.behavior,
      browser_style: native_node.browser_style
    }

    canonical_projection = %{
      behavior: canonical_node.behavior,
      browser_style: canonical_node.browser_style
    }

    if native_projection == canonical_projection do
      nil
    else
      diagnostic(
        :frontend_style_realization,
        :frontend_realization_drift,
        id,
        "Inspect ElmUi.FrontendRuntime.Realization and StyleRealization for browser-facing drift",
        native_projection,
        canonical_projection
      )
    end
  end

  defp diagnostic(seam, reason, id, action, native_value, canonical_value) do
    %{
      seam: seam,
      reason: reason,
      id: id,
      action: action,
      native: native_value,
      canonical: canonical_value
    }
  end

  defp no_reason?(diagnostics, reason) do
    not Enum.any?(diagnostics, &(&1.reason == reason))
  end

  defp index_by_id(nodes) do
    Map.new(nodes, &{to_string(&1.id), &1})
  end
end
