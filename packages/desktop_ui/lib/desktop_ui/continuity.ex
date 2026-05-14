defmodule DesktopUi.Continuity do
  @moduledoc """
  Native-versus-canonical and cross-target continuity diagnostics for
  `desktop_ui`.
  """

  alias DesktopUi.Inspection
  alias DesktopUi.Runtime
  alias DesktopUi.Runtime.State

  @seams [:widget_identity, :style_resolution, :platform_semantics]
  @diagnostic_kinds [
    :kind_mismatch,
    :resolved_style_mismatch,
    :shared_semantics_drift,
    :allowed_variation_drift
  ]

  @spec seams() :: [atom()]
  def seams, do: @seams

  @spec diagnostic_kinds() :: [atom()]
  def diagnostic_kinds, do: @diagnostic_kinds

  @spec contract() :: map()
  def contract do
    %{
      seams: seams(),
      diagnostic_kinds: diagnostic_kinds(),
      validation: [:pass, :fail]
    }
  end

  @spec compare(State.t(), State.t()) :: map()
  def compare(%State{} = native_state, %State{} = canonical_state) do
    native_snapshot = Inspection.runtime_snapshot(native_state)
    canonical_snapshot = Inspection.runtime_snapshot(canonical_state)

    diagnostics =
      build_diagnostics(
        index_by_id(native_snapshot.style.style_nodes),
        index_by_id(canonical_snapshot.style.style_nodes),
        native_snapshot.platform.profile,
        canonical_snapshot.platform.profile
      )

    %{
      native: native_snapshot,
      canonical: canonical_snapshot,
      diagnostics: diagnostics,
      continuity: summary(diagnostics)
    }
  end

  @spec compare_targets(map(), keyword()) :: {:ok, map()} | {:error, term()}
  def compare_targets(screen, opts \\ []) when is_map(screen) do
    targets = Keyword.get(opts, :targets, DesktopUi.Platform.targets())

    with {:ok, states} <- mount_targets(screen, targets) do
      snapshots =
        Map.new(states, fn {target, state} -> {target, Inspection.runtime_snapshot(state)} end)

      diagnostics = target_diagnostics(snapshots, targets)

      {:ok,
       %{
         targets: snapshots,
         diagnostics: diagnostics,
         continuity: summary(diagnostics)
       }}
    end
  end

  defp mount_targets(screen, targets) do
    Enum.reduce_while(targets, {:ok, %{}}, fn target, {:ok, acc} ->
      case Runtime.mount_native_screen(screen, platform_target: target) do
        {:ok, state} -> {:cont, {:ok, Map.put(acc, target, state)}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  defp target_diagnostics(snapshots, [baseline_target | rest]) do
    baseline_snapshot = Map.fetch!(snapshots, baseline_target)
    baseline_nodes = index_by_id(baseline_snapshot.style.style_nodes)

    Enum.flat_map(rest, fn target ->
      target_snapshot = Map.fetch!(snapshots, target)

      build_diagnostics(
        baseline_nodes,
        index_by_id(target_snapshot.style.style_nodes),
        baseline_snapshot.platform.profile,
        target_snapshot.platform.profile
      )
      |> Enum.map(&Map.put(&1, :baseline_target, baseline_target))
    end)
  end

  defp target_diagnostics(_snapshots, []), do: []

  defp build_diagnostics(left_nodes, right_nodes, left_profile, right_profile) do
    shared_ids =
      left_nodes
      |> Map.keys()
      |> Enum.filter(&Map.has_key?(right_nodes, &1))
      |> Enum.sort()

    shared_ids
    |> Enum.flat_map(fn id ->
      continuity_diagnostics(id, left_nodes[id], right_nodes[id])
    end)
    |> Kernel.++(platform_diagnostics(left_profile, right_profile))
  end

  defp continuity_diagnostics(id, left_node, right_node) do
    left_styles = style_projection(left_node.resolved_styles)
    right_styles = style_projection(right_node.resolved_styles)

    []
    |> maybe_add_diagnostic(
      left_node.kind != right_node.kind,
      :widget_identity,
      :kind_mismatch,
      id,
      left_node.kind,
      right_node.kind
    )
    |> maybe_add_diagnostic(
      left_styles != right_styles,
      :style_resolution,
      :resolved_style_mismatch,
      id,
      left_styles,
      right_styles
    )
  end

  defp platform_diagnostics(left_profile, right_profile) do
    []
    |> maybe_add_diagnostic(
      left_profile.shared_semantics != right_profile.shared_semantics,
      :platform_semantics,
      :shared_semantics_drift,
      :shared_semantics,
      left_profile.shared_semantics,
      right_profile.shared_semantics
    )
    |> maybe_add_diagnostic(
      left_profile.allowed_variation != right_profile.allowed_variation,
      :platform_semantics,
      :allowed_variation_drift,
      :allowed_variation,
      left_profile.allowed_variation,
      right_profile.allowed_variation
    )
  end

  defp summary(diagnostics) do
    %{
      widget_identity_match?: no_reason?(diagnostics, :kind_mismatch),
      style_resolution_match?: no_reason?(diagnostics, :resolved_style_mismatch),
      platform_semantics_match?:
        no_reason?(diagnostics, :shared_semantics_drift) and
          no_reason?(diagnostics, :allowed_variation_drift),
      validation: %{
        status: if(diagnostics == [], do: :pass, else: :fail),
        failing_seams: diagnostics |> Enum.map(& &1.seam) |> Enum.uniq() |> Enum.sort(),
        actionable_output: diagnostics
      }
    }
  end

  defp maybe_add_diagnostic(diagnostics, false, _seam, _reason, _id, _left, _right),
    do: diagnostics

  defp maybe_add_diagnostic(diagnostics, true, seam, reason, id, left, right) do
    diagnostics ++ [%{seam: seam, reason: reason, id: id, left: left, right: right}]
  end

  defp no_reason?(diagnostics, reason) do
    not Enum.any?(diagnostics, &(&1.reason == reason))
  end

  defp style_projection(styles) do
    Map.take(styles, [:theme, :variant, :semantic_role, :border, :padding, :intent, :elevation])
  end

  defp index_by_id(nodes) do
    Map.new(nodes, &{to_string(&1.id), &1})
  end
end
