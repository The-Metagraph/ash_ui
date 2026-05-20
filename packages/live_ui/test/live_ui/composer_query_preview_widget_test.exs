defmodule LiveUi.ComposerQueryPreviewWidgetTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias UnifiedIUR.Widgets.Components

  describe "ComposerQueryPreview Phoenix.Component" do
    test "is registered in the layer shell component family" do
      metadata = LiveUi.Component.metadata(LiveUi.Widgets.ComposerQueryPreview)

      assert LiveUi.Widgets.ComposerQueryPreview in LiveUi.Widgets.LayerShellAndCallout.modules()

      assert LiveUi.Widgets.ComposerQueryPreview in LiveUi.Widgets.layer_shell_and_callout_modules()

      assert LiveUi.Widgets.ComposerQueryPreview in LiveUi.Widgets.modules()
      assert metadata.family == :layer_shell_and_callout
      assert metadata.name == :composer_query_preview
    end

    test "renders ready results without the generic component fallback" do
      html =
        render_component(&LiveUi.Widgets.ComposerQueryPreview.component/1, %{
          id: "query-preview",
          composer_id: "composer-main",
          query: "release blockers",
          preview_state: :ready,
          explanation: "Three likely blockers found.",
          metrics: %{results_count: 3, duration_ms: 42, sources_visited: 8},
          findings: [
            %{id: "finding-1", n: 1, snippet: "Conformance missing", confidence: 0.91}
          ],
          max_findings_shown: 2
        })

      assert html =~ ~s(data-live-ui-widget="composer-query-preview")
      assert html =~ ~s(data-composer-id="composer-main")
      assert html =~ ~s(data-preview-state="ready")
      assert html =~ "Three likely blockers found."
      assert html =~ "Conformance missing"
      assert html =~ "3"
      assert html =~ "0.04s"
      refute html =~ ~s(data-live-ui-component-kind)
      refute html =~ "data-live-ui-intent"
    end

    test "renders loading and error states with accessibility state" do
      loading_html =
        render_component(&LiveUi.Widgets.ComposerQueryPreview.component/1, %{
          id: "loading-preview",
          composer_id: "composer-main",
          query: "status",
          preview_state: :loading
        })

      error_html =
        render_component(&LiveUi.Widgets.ComposerQueryPreview.component/1, %{
          id: "error-preview",
          composer_id: "composer-main",
          query: "status",
          preview_state: :error,
          error_message: "No index available"
        })

      assert loading_html =~ ~s(aria-busy="true")
      refute loading_html =~ "live-ui-composer-query-preview__actions"
      assert error_html =~ ~s(role="alert")
      assert error_html =~ "No index available"
    end

    test "accepts renderer-supplied canonical action attrs" do
      html =
        render_component(&LiveUi.Widgets.ComposerQueryPreview.component/1, %{
          id: "query-preview-actions",
          composer_id: "composer-main",
          query: "release blockers",
          preview_state: :empty,
          dismiss_attrs: %{
            "phx-click": "canonical_interaction",
            "phx-value-widget": "composer_query_preview"
          },
          open_attrs: %{
            "phx-click": "canonical_interaction",
            "phx-value-widget": "composer_query_preview"
          },
          save_attrs: %{
            "phx-click": "canonical_interaction",
            "phx-value-widget": "composer_query_preview"
          }
        })

      assert html =~ ~s(phx-click="canonical_interaction")
      assert html =~ ~s(phx-value-widget="composer_query_preview")
      refute html =~ "open in Ask"
    end
  end

  describe "LiveUi.Renderer integration" do
    test "dispatches canonical composer_query_preview through native component boundary" do
      element =
        Components.composer_query_preview(
          id: "query-preview-renderer",
          composer_id: "composer-main",
          query: "release blockers",
          preview_state: :ready,
          explanation: "Three likely blockers found.",
          metrics: %{results_count: 3, duration_ms: 42, sources_visited: 8},
          findings: [
            %{id: "finding-1", n: 1, snippet: "Conformance missing", confidence: 0.91}
          ]
        )

      html =
        render_component(&LiveUi.Renderer.render/1, %{
          element: element,
          event_target: "#runtime-host"
        })

      assert html =~ ~s(data-live-ui-widget="composer-query-preview")
      assert html =~ ~s(phx-click="canonical_interaction")
      assert html =~ ~s(phx-target="#runtime-host")
      assert html =~ ~s(phx-value-widget="composer_query_preview")
      assert html =~ ~s(phx-value-query="release blockers")
      refute html =~ ~s(data-live-ui-component-kind)
      refute html =~ "open in Ask"
    end
  end
end
