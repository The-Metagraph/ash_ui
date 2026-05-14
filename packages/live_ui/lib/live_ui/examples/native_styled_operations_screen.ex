defmodule LiveUi.Examples.NativeStyledOperationsScreen do
  @moduledoc """
  Maintained native styling example for overlay-driven operational workflows.
  """

  alias LiveUi.Examples.StyledExampleStyles

  use LiveUi.Screen, id: :native_styled_operations, title: "Native Styled Operations"

  @impl true
  def mount_defaults do
    %{
      nodes: [
        %{id: "node-a", status: :up},
        %{id: "node-b", status: :up}
      ],
      summary: %{healthy: 2, degraded: 0},
      operations: [
        %{kind: :text, position: %{x: 2, y: 3}, text: "Ops"}
      ]
    }
  end

  @impl true
  def render(assigns) do
    theme = LiveUi.Theme.default()

    assigns =
      assigns
      |> Map.put(
        :overlay_style,
        LiveUi.Style.component_assigns(:overlay_surface,
          theme: theme,
          style: StyledExampleStyles.operations_overlay()
        )
      )
      |> Map.put(
        :viewport_style,
        LiveUi.Style.component_assigns(:viewport,
          theme: theme,
          style: StyledExampleStyles.operations_viewport()
        )
      )
      |> Map.put(
        :canvas_style,
        LiveUi.Style.component_assigns(:canvas,
          theme: theme,
          style: StyledExampleStyles.operations_canvas()
        )
      )
      |> Map.put(
        :dialog_style,
        LiveUi.Style.component_assigns(:dialog,
          theme: theme,
          style: StyledExampleStyles.operations_dialog()
        )
      )
      |> Map.put(
        :cluster_style,
        LiveUi.Style.component_assigns(:cluster_dashboard,
          theme: theme,
          style: StyledExampleStyles.operations_cluster()
        )
      )

    ~H"""
    <LiveUi.Widgets.OverlaySurface.render
      id="ops-overlay"
      mode="stacked"
      background_fill="scrim"
      {@overlay_style}
    >
      <:base>
        <LiveUi.Widgets.Viewport.render
          id="ops-viewport"
          offset_y={6}
          width="80"
          height="24"
          sync_group="ops"
          {@viewport_style}
        >
          <LiveUi.Widgets.Canvas.render
            id="ops-canvas"
            operations={@operations}
            width={80}
            height={24}
            background="analysis"
            {@canvas_style}
          />
        </LiveUi.Widgets.Viewport.render>
      </:base>
      <:overlay>
        <LiveUi.Widgets.Dialog.render id="ops-dialog" title="Cluster Health" {@dialog_style}>
          <LiveUi.Widgets.ClusterDashboard.render
            id="ops-cluster"
            nodes={@nodes}
            summary={@summary}
            {@cluster_style}
          />
        </LiveUi.Widgets.Dialog.render>
      </:overlay>
    </LiveUi.Widgets.OverlaySurface.render>
    """
  end

  def metadata do
    %{
      id: :native_styled_operations,
      title: title(),
      families: [:styling, :overlay, :operational, :continuity],
      comparable_to: :canonical_styled_operations,
      summary: "Native styled operational screen paired with its canonical equivalent."
    }
  end
end
