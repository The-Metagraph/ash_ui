defmodule LiveUi.Examples.CanonicalStyledOperations do
  @moduledoc """
  Maintained canonical styling example for overlay and operational continuity.
  """

  alias LiveUi.Examples.StyledExampleStyles
  alias UnifiedIUR.{Canvas, Layer, Viewport}
  alias UnifiedIUR.Widgets.Advanced

  def element do
    base =
      Viewport.region(
        Canvas.surface(
          [
            %{kind: :text, position: %{x: 2, y: 3}, text: "Ops"}
          ],
          id: "ops-canvas",
          width: 80,
          height: 24,
          background: "analysis",
          style: StyledExampleStyles.operations_canvas(),
          theme: %{id: :live_ui}
        ),
        id: "ops-viewport",
        offset: %{x: 0, y: 6},
        width: "80",
        height: "24",
        sync_group: "ops",
        style: StyledExampleStyles.operations_viewport(),
        theme: %{id: :live_ui}
      )

    dialog =
      Layer.dialog(
        Advanced.cluster_dashboard(
          [
            %{id: "node-a", status: :up},
            %{id: "node-b", status: :up}
          ],
          id: "ops-cluster",
          summary: %{healthy: 2, degraded: 0},
          style: StyledExampleStyles.operations_cluster(),
          theme: %{id: :live_ui}
        ),
        id: "ops-dialog",
        title: "Cluster Health",
        style: StyledExampleStyles.operations_dialog(),
        theme: %{id: :live_ui}
      )

    Layer.overlay(
      base,
      [dialog],
      id: "ops-overlay",
      mode: :stacked,
      background_fill: :scrim,
      style: StyledExampleStyles.operations_overlay(),
      theme: %{id: :live_ui}
    )
  end

  def metadata do
    %{
      id: :canonical_styled_operations,
      title: "Canonical Styled Operations",
      families: [:styling, :overlay, :operational, :continuity],
      comparable_to: :native_styled_operations,
      summary:
        "Canonical operational screen that reuses the native overlay and dashboard widgets."
    }
  end
end
