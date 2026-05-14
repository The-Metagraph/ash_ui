defmodule LiveUi.RendererStyleTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias UnifiedIUR.{Canvas, Container, Layer, Viewport}
  alias UnifiedIUR.Widgets.Foundational

  test "renderer lowers canonical style and theme values into native foundational markers" do
    element =
      Container.box(
        [
          Foundational.button("Save",
            id: "save-button",
            style: %{
              emphasis: %{tone: :critical},
              extra: %{class: "canonical-button"}
            },
            theme: %{id: :live_ui, variant: :quiet, state: :active}
          )
        ],
        id: "profile-panel",
        style: %{
          emphasis: %{tone: :surface},
          extra: %{class: "canonical-panel"}
        },
        theme: %{id: :live_ui, variant: :panel}
      )

    html = render_component(&LiveUi.Renderer.render/1, %{element: element})

    assert html =~ "data-live-ui-widget=\"box\""
    assert html =~ "data-live-ui-tone=\"surface\""
    assert html =~ "data-live-ui-variant=\"panel\""
    assert html =~ "canonical-panel"
    assert html =~ "data-live-ui-widget=\"button\""
    assert html =~ "data-live-ui-tone=\"critical\""
    assert html =~ "data-live-ui-variant=\"quiet\""
    assert html =~ "data-live-ui-state=\"active\""
    assert html =~ "canonical-button"
  end

  test "renderer lowers canonical style meaning for layered, viewport, and canvas constructs" do
    layered =
      Layer.overlay(
        Viewport.region(
          Canvas.surface(
            [
              %{kind: :text, position: %{x: 3, y: 2}, text: "Plot"}
            ],
            id: "analytics-canvas",
            style: %{
              background: "#08101f",
              border_color: "#334155",
              extra: %{class: "analytics-canvas"}
            },
            theme: %{id: :live_ui, variant: :analysis}
          ),
          id: "analytics-viewport",
          style: %{
            background: "#020617",
            border_color: "#1d4ed8",
            sizing: %{height: "18rem"},
            extra: %{class: "analytics-viewport"}
          },
          theme: %{id: :live_ui}
        ),
        [
          {:modal,
           Layer.dialog(
             Container.content([{:content, Foundational.text("Styled overlay")}],
               id: "overlay-copy"
             ),
             id: "style-dialog",
             title: "Style",
             style: %{border_color: "#60a5fa", background: "#0f172a"}
           )}
        ],
        id: "analytics-overlay",
        style: %{background: "#020617", extra: %{class: "analytics-overlay"}},
        theme: %{id: :live_ui, variant: :modal}
      )

    html = render_component(&LiveUi.Renderer.render/1, %{element: layered})

    assert html =~ "data-live-ui-widget=\"overlay-surface\""
    assert html =~ "data-live-ui-variant=\"modal\""
    assert html =~ "analytics-overlay"
    assert html =~ "--live-ui-background: #020617"
    assert html =~ "data-live-ui-widget=\"viewport\""
    assert html =~ "analytics-viewport"
    assert html =~ "--live-ui-height: 18rem"
    assert html =~ "--live-ui-border-color: #1d4ed8"
    assert html =~ "data-live-ui-widget=\"canvas\""
    assert html =~ "data-live-ui-variant=\"analysis\""
    assert html =~ "analytics-canvas"
    assert html =~ "live-ui-canvas-analysis"
    assert html =~ "--live-ui-background: #08101f"
    assert html =~ "--live-ui-border-color: #334155"
    assert html =~ "--live-ui-border-color: #60a5fa"
  end

  test "equivalent canonical style input produces deterministic native styling output" do
    left =
      Foundational.text("Ready",
        id: "status",
        style: %{emphasis: %{tone: :success}},
        theme: %{id: :live_ui}
      )

    right =
      Foundational.text("Ready",
        id: "status",
        style: %{emphasis: %{tone: :success}, extra: %{}},
        theme: %{id: :live_ui, token_refs: []}
      )

    assert render_component(&LiveUi.Renderer.render/1, %{element: left}) ==
             render_component(&LiveUi.Renderer.render/1, %{element: right})
  end

  test "renderer forwards realized browser attrs to foundational widgets" do
    element =
      Container.box(
        [
          Foundational.text("Ready",
            id: "status-copy",
            style: %{foreground: "#22c55e", text: %{underline?: true}}
          ),
          Foundational.button("Save",
            id: "save-button",
            style: %{background: "#1d4ed8", foreground: "#ffffff"}
          ),
          UnifiedIUR.Widgets.Input.text_input(
            id: "name-input",
            name: :name,
            placeholder: "Name",
            style: %{background: "#0f172a", border_color: "#38bdf8"}
          )
        ],
        id: "profile-panel",
        style: %{
          background: "#020617",
          border_color: "#334155",
          border: %{radius: :lg}
        },
        theme: %{id: :live_ui, variant: :panel}
      )

    html = render_component(&LiveUi.Renderer.render/1, %{element: element})

    assert html =~ "data-live-ui-browser-style=\"mixed\""
    assert html =~ "--live-ui-background: #020617"
    assert html =~ "--live-ui-border-color: #334155"
    assert html =~ "--live-ui-border-radius: 1rem"
    assert html =~ "--live-ui-foreground: #22c55e"
    assert html =~ "--live-ui-text-decoration: underline"
    assert html =~ "--live-ui-background: #1d4ed8"
    assert html =~ "--live-ui-foreground: #ffffff"
    assert html =~ "--live-ui-border-color: #38bdf8"
  end

  test "renderer preserves legacy local classes and attrs alongside realized output" do
    element =
      Foundational.text("Legacy",
        id: "legacy-copy",
        style: %{
          foreground: "#f97316",
          extra: %{
            class: "legacy-copy",
            attrs: %{"data-legacy" => "true"}
          }
        }
      )

    html = render_component(&LiveUi.Renderer.render/1, %{element: element})

    assert html =~ "legacy-copy"
    assert html =~ "data-legacy=\"true\""
    assert html =~ "--live-ui-foreground: #f97316"
  end

  test "renderer lowers canonical layout geometry into the same browser-visible attrs as native layout primitives" do
    element =
      UnifiedIUR.Layout.grid(
        [
          UnifiedIUR.Layout.row(
            [Foundational.text("Row child", id: "row-copy")],
            id: "metrics-row",
            gap: "sm",
            padding: "lg",
            align: "center",
            justify: "between",
            width: "80%"
          ),
          UnifiedIUR.Layout.column(
            [Foundational.text("Column child", id: "column-copy")],
            id: "detail-column",
            gap: "md",
            padding: "sm",
            align: "end",
            justify: "start",
            max_width: "28rem"
          )
        ],
        id: "analytics-grid",
        columns: 2,
        rows: 1,
        gap: "lg",
        padding: "md",
        align: "center",
        justify: "between",
        width: "100%",
        min_height: "12rem"
      )

    html = render_component(&LiveUi.Renderer.render/1, %{element: element})

    assert html =~ "--live-ui-grid-columns: 2"
    assert html =~ "--live-ui-grid-rows: 1"
    assert html =~ "--live-ui-gap: 1rem"
    assert html =~ "--live-ui-padding: 0.75rem"
    assert html =~ "--live-ui-align-items: center"
    assert html =~ "--live-ui-justify-content: space-between"
    assert html =~ "--live-ui-width: 100%"
    assert html =~ "--live-ui-min-height: 12rem"
    assert html =~ "--live-ui-max-width: 28rem"
  end
end
