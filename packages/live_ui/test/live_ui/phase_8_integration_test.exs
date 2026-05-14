defmodule LiveUi.Phase8IntegrationTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest

  alias UnifiedIUR.{Canvas, Layer, Layout, Viewport}
  alias UnifiedIUR.Widgets.Navigation
  alias UnifiedIUR.Widgets.{Advanced, Data, Feedback, Foundational}

  test "layout and layered browser realization converge across native and canonical rendering" do
    native_surface =
      render_component(
        &LiveUi.Widgets.OverlaySurface.render/1,
        %{
          id: "native-overlay",
          background_fill: "scrim",
          base: [
            %{
              __slot__: :base,
              inner_block: fn _, _ ->
                Phoenix.HTML.raw(
                  render_component(
                    &LiveUi.Widgets.Viewport.render/1,
                    %{
                      id: "native-viewport",
                      axis: "both",
                      width: "28rem",
                      height: "18rem",
                      offset_x: 4,
                      offset_y: 6,
                      inner_block: [
                        %{
                          __slot__: :inner_block,
                          inner_block: fn _, _ ->
                            render_component(
                              &LiveUi.Widgets.Canvas.render/1,
                              %{
                                id: "native-canvas",
                                width: 32,
                                height: 12,
                                background: "analysis",
                                operations: [
                                  %{kind: :text, position: %{x: 2, y: 3}, text: "Plot"}
                                ]
                              }
                              |> Map.merge(
                                LiveUi.Style.component_assigns(:canvas,
                                  theme: LiveUi.Theme.default(),
                                  variant: :analysis,
                                  style: %{border_color: "#38bdf8"}
                                )
                              )
                            )
                          end
                        }
                      ]
                    }
                    |> Map.merge(
                      LiveUi.Style.component_assigns(:viewport,
                        theme: LiveUi.Theme.default(),
                        style: %{background: "#020617", border_color: "#1d4ed8"}
                      )
                    )
                  )
                )
              end
            }
          ],
          overlay: [
            %{
              __slot__: :overlay,
              inner_block: fn _, _ ->
                render_component(
                  &LiveUi.Widgets.Dialog.render/1,
                  %{
                    id: "native-dialog",
                    title: "Style",
                    size: "lg",
                    inner_block: [slot_text(:inner_block, "Layered details")]
                  }
                  |> Map.merge(
                    LiveUi.Style.component_assigns(:dialog,
                      theme: LiveUi.Theme.default(),
                      style: %{background: "#0f172a", border_color: "#60a5fa"}
                    )
                  )
                )
              end
            }
          ]
        }
        |> Map.merge(
          LiveUi.Style.component_assigns(:overlay_surface,
            theme: LiveUi.Theme.default(),
            variant: :modal,
            style: %{background: "#020617"}
          )
        )
      )

    canonical_surface =
      render_component(&LiveUi.Renderer.render/1,
        element:
          Layer.overlay(
            Viewport.region(
              Canvas.surface(
                [%{kind: :text, position: %{x: 2, y: 3}, text: "Plot"}],
                id: "canonical-canvas",
                width: 32,
                height: 12,
                background: :analysis,
                style: %{border_color: "#38bdf8"},
                theme: %{id: :live_ui, variant: :analysis}
              ),
              id: "canonical-viewport",
              axis: :both,
              width: "28rem",
              height: "18rem",
              offset: %{x: 4, y: 6},
              style: %{background: "#020617", border_color: "#1d4ed8"}
            ),
            [
              {:modal,
               Layer.dialog(
                 Layout.column([Foundational.text("Layered details")]),
                 id: "canonical-dialog",
                 title: "Style",
                 size: :lg,
                 style: %{background: "#0f172a", border_color: "#60a5fa"}
               )}
            ],
            id: "canonical-overlay",
            background_fill: :scrim,
            style: %{background: "#020617"},
            theme: %{id: :live_ui, variant: :modal}
          )
      )

    for fragment <- [
          "--live-ui-overlay-scrim: hsl(222 47% 11% / 0.76)",
          "--live-ui-background: #020617",
          "--live-ui-height: 18rem",
          "--live-ui-viewport-offset-y: 6",
          "--live-ui-canvas-columns: 32",
          "--live-ui-canvas-rows: 12",
          "--live-ui-border-color: #60a5fa"
        ] do
      assert native_surface =~ fragment
      assert canonical_surface =~ fragment
    end
  end

  test "advanced widgets and supported state variants remain aligned across native and canonical rendering" do
    native_widgets =
      Phoenix.HTML.raw("""
      #{render_component(&LiveUi.Widgets.Tabs.render/1, %{id: "native-tabs", active_item: "details", items: [%{id: "details", label: "Details"}, %{id: "history", label: "History", disabled: true}]} |> Map.merge(LiveUi.Style.component_assigns(:tabs, theme: LiveUi.Theme.default(), state: :focused, style: %{background: "#0f172a", border_color: "#1d4ed8"})))}
      #{render_component(&LiveUi.Widgets.List.render/1, %{id: "native-list", items: [%{id: "overview", label: "Overview", selected: true}, %{id: "activity", label: "Activity"}]} |> Map.merge(LiveUi.Style.component_assigns(:list, theme: LiveUi.Theme.default(), state: :selected, style: %{background: "#111827", border_color: "#334155"})))}
      #{render_component(&LiveUi.Widgets.Status.render/1, %{id: "native-status", text: "Healthy", severity: "success", status: "ready"} |> Map.merge(LiveUi.Style.component_assigns(:status, theme: LiveUi.Theme.default(), state: :active, style: %{state_variants: %{active: %{foreground: "#ffffff", border_color: "#22c55e"}}})))}
      #{render_component(&LiveUi.Widgets.Toast.render/1, %{id: "native-toast", severity: "success", inner_block: [slot_text(:inner_block, "Saved")]} |> Map.merge(LiveUi.Style.component_assigns(:toast, theme: LiveUi.Theme.default(), state: :active, style: %{background: "#14532d", border_color: "#22c55e"})))}
      """)
      |> Phoenix.HTML.safe_to_string()

    canonical_widgets =
      render_component(&LiveUi.Renderer.render/1,
        element:
          Layout.column([
            Navigation.tabs(
              [
                %{id: "details", label: "Details", active?: true},
                %{id: "history", label: "History", disabled?: true}
              ],
              id: "canonical-tabs",
              active_item: "details",
              style: %{background: "#0f172a", border_color: "#1d4ed8"},
              theme: %{id: :live_ui, state: :focused}
            ),
            Data.list(
              [
                %{id: "overview", label: "Overview", selected?: true},
                %{id: "activity", label: "Activity"}
              ],
              id: "canonical-list",
              style: %{background: "#111827", border_color: "#334155"},
              theme: %{id: :live_ui, state: :selected}
            ),
            Feedback.status("Healthy",
              id: "canonical-status",
              severity: :success,
              status: :ready,
              style: %{
                state_variants: %{active: %{foreground: "#ffffff", border_color: "#22c55e"}}
              },
              theme: %{id: :live_ui, state: :active}
            ),
            Advanced.markdown_viewer("# Release Notes",
              id: "canonical-markdown",
              style: %{background: "#020617", border_color: "#475569"}
            ),
            Advanced.stream_widget(
              [%{id: "evt-1", message: "ready", severity: :success}],
              id: "canonical-stream",
              style: %{background: "#020617", border_color: "#1d4ed8"}
            ),
            Advanced.cluster_dashboard(
              [%{id: "node-a", status: :up}],
              id: "canonical-cluster",
              summary: %{healthy: 1},
              style: %{background: "#08101f", border_color: "#059669"}
            ),
            Canvas.bar_chart(
              [%{id: :cpu, label: "CPU", values: [10, 20, 30]}],
              id: "canonical-bars",
              style: %{background: "#0b1120", border_color: "#0ea5e9"}
            ),
            Layer.toast(Foundational.text("Saved"),
              id: "canonical-toast",
              severity: :success,
              style: %{background: "#14532d", border_color: "#22c55e"},
              theme: %{id: :live_ui, state: :active}
            )
          ])
      )

    for fragment <- [
          "data-live-ui-widget=\"tabs\"",
          "data-live-ui-state=\"focused\"",
          "--live-ui-background: #0f172a",
          "data-live-ui-widget=\"list\"",
          "data-live-ui-state=\"selected\"",
          "--live-ui-border-color: #334155",
          "data-live-ui-widget=\"status\"",
          "data-live-ui-state=\"active\"",
          "--live-ui-foreground: #ffffff",
          "disabled",
          "data-live-ui-widget=\"toast\"",
          "--live-ui-background: #14532d"
        ] do
      assert native_widgets =~ fragment
      assert canonical_widgets =~ fragment
    end

    assert canonical_widgets =~ "data-live-ui-widget=\"markdown-viewer\""
    assert canonical_widgets =~ "data-live-ui-widget=\"stream-widget\""
    assert canonical_widgets =~ "data-live-ui-widget=\"cluster-dashboard\""
    assert canonical_widgets =~ "data-live-ui-widget=\"bar-chart\""
  end

  test "phase 8 stylesheet and diagnostics keep advanced browser styling reviewable" do
    css = LiveUi.Stylesheet.css()

    for selector <- [
          "[data-live-ui-widget=\"tabs\"] [role=\"tab\"][aria-selected=\"true\"]",
          "[data-live-ui-widget=\"list\"] li[data-selected=\"true\"]",
          "[data-live-ui-widget=\"toast\"][data-live-ui-open=\"false\"]",
          "[data-live-ui-widget=\"bar-chart\"]::before",
          "[data-live-ui-widget=\"tabs\"][data-live-ui-state=\"focused\"]"
        ] do
      assert css =~ selector
    end

    profile =
      LiveUi.Style.resolve(LiveUi.Theme.default(), :tabs,
        state: :active,
        local_style: %{
          text: %{blink?: true},
          state_variants: %{
            active: %{foreground: "#ffffff"},
            staged: %{foreground: "#f9a8d4"}
          }
        }
      )

    diagnostics = LiveUi.Style.browser_diagnostics(profile)

    assert diagnostics.fallback == :mixed
    assert diagnostics.unsupported_fields == ["text.blink?"]
    assert diagnostics.ignored_fields == ["state_variants.staged"]
    assert profile.browser.attrs["style"] =~ "--live-ui-foreground: #ffffff"
  end

  defp slot_text(slot_name, content) do
    %{
      __slot__: slot_name,
      inner_block: fn _, _ -> content end
    }
  end
end
