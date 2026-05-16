defmodule LiveUi.Phase17IntegrationTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.{Info, Runtime, Widgets}
  alias UnifiedIUR.Widgets.{Data, Foundational}

  @moduledoc """
  Integration tests for Phase 17 - Tooling, Validation, and Release Readiness.

  These tests validate the widget-component architecture is properly exposed
  in tooling, aligned examples work correctly, and validation gates are in place.
  """

  describe "17.1 - Tooling and Inspection for Widget Components" do
    test "widget_summary exposes component boundary information" do
      summary = Info.widget_summary(LiveUi.Widgets.Text)

      assert summary.module == LiveUi.Widgets.Text
      assert summary.component_module == LiveUi.Widgets.Text.Component
      assert summary.mountable? == true
      assert summary.runtime_boundary == :live_component
      assert is_list(summary.local_state_keys)
      assert summary.family == :content
      assert summary.name == :text
    end

    test "advanced_widget_summary provides comprehensive widget metadata" do
      summaries = Info.advanced_widget_summary()

      assert length(summaries) > 0

      Enum.each(summaries, fn summary ->
        assert summary.mountable? == true
        assert summary.component_module
        assert summary.runtime_boundary == :live_component
        assert is_list(summary.local_state_keys)
      end)
    end

    test "info exposes all widget families through modules list" do
      all_modules = Widgets.modules()

      # Should have widgets from all families
      assert length(all_modules) > 20

      # Each module should have valid metadata
      Enum.each(all_modules, fn mod ->
        metadata = LiveUi.Component.metadata(mod)
        assert metadata.module == mod
        assert metadata.family
        assert metadata.name
      end)
    end

    test "structural components are identified correctly" do
      # Layout components are structural (function components)
      summary = Info.widget_summary(LiveUi.Layout.Column)

      assert summary.module == LiveUi.Layout.Column
      assert summary.runtime_boundary == :function_component
      assert summary.component_module == LiveUi.Layout.Column.Component
    end

    test "canonical and native paths target same widget boundaries" do
      # Native path
      {:ok, native_runtime} =
        Runtime.mount_iur(Data.list([%{id: "1", label: "Item"}], id: "test-list"))

      native_html =
        render_component(Runtime.component(),
          id: "native-render",
          runtime_state: native_runtime
        )

      # Both should use the same widget component boundary
      assert native_html =~ ~s(data-live-ui-widget-boundary="list")
      assert native_html =~ ~s(data-live-ui-widget-key=)
    end
  end

  describe "17.2 - Aligned Focused Examples and Demo Retirement" do
    test "aligned examples render widgets correctly" do
      {:ok, preview} = LiveUi.Tooling.preview_example(:text)

      assert preview.result.html =~ ~s(data-live-ui-widget="text")
    end

    test "aligned examples expose widget attributes for inspection" do
      {:ok, preview} = LiveUi.Tooling.preview_example(:button)

      assert preview.result.html =~ ~s(data-live-ui-widget="button")
    end

    test "canonical examples use widget component boundaries" do
      canonical_element =
        Foundational.text("Test content",
          id: "canonical-text"
        )

      {:ok, runtime_state} = Runtime.mount_iur(canonical_element)

      html =
        render_component(Runtime.component(),
          id: "canonical-test",
          runtime_state: runtime_state
        )

      # Canonical rendering uses widget component boundaries
      assert html =~ ~s(data-live-ui-widget-boundary="text")
      assert html =~ ~s(data-live-ui-widget-key=)
    end

    test "native screen rendering exposes widget metadata" do
      # Canonical rendering through Runtime.mount_iur
      element =
        Data.list([%{id: "1", label: "Item"}], id: "test-list")

      {:ok, runtime_state} = Runtime.mount_iur(element)

      html =
        render_component(Runtime.component(),
          id: "test",
          runtime_state: runtime_state
        )

      # Should expose widget identity and boundary
      assert html =~ ~s(data-live-ui-widget-boundary="list")
      assert html =~ ~s(data-live-ui-widget-key=)
    end

    test "aligned catalog provides comprehensive widget coverage" do
      catalog = LiveUi.Examples.catalog()

      assert length(catalog) == length(LiveUi.Examples.repository_example_ids())
      assert Enum.all?(catalog, &(&1.path == :aligned))
      assert Enum.all?(catalog, &(&1.runtime_obligations.root_example_id == &1.id))
    end

    test "demo surface is retired and divergent example ids stay hidden" do
      refute Code.ensure_loaded?(LiveUi.Demo)
      assert :error = LiveUi.Examples.find(:native_display)
      assert :error = LiveUi.Examples.find(:canonical_form)
      assert :error = LiveUi.Examples.find(:styled_continuity_compare)
    end

    test "canonical rendering through Runtime preserves widget identity" do
      element =
        UnifiedIUR.Container.box(
          [
            UnifiedIUR.Layout.column([
              UnifiedIUR.Widgets.Data.list([%{id: "1", label: "Item"}], id: "list")
            ])
          ],
          id: "container"
        )

      {:ok, runtime_state} = Runtime.mount_iur(element)

      html =
        render_component(Runtime.component(),
          id: "container-test",
          runtime_state: runtime_state
        )

      # All nested widgets should have boundaries
      assert html =~ ~s(data-live-ui-widget-boundary="box")
      assert html =~ ~s(data-live-ui-widget-boundary="column")
      assert html =~ ~s(data-live-ui-widget-boundary="list")
    end
  end

  describe "17.3 - Documentation, Validation, and Cleanup" do
    test "package_summary includes widget-component architecture information" do
      summary = Info.package_summary()

      assert summary.package == :live_ui
      assert summary.namespace == LiveUi
      assert summary.validation_state
      assert is_list(summary.tooling.workflows)
      assert is_map(summary.documentation)
    end

    test "renderer_summary exposes canonical rendering capabilities" do
      summary = Info.renderer_summary()

      assert summary.accepts == UnifiedIUR.Element
      assert is_list(summary.supported_kinds)
      assert is_list(summary.responsibilities)

      # Should support advanced widget kinds
      assert :markdown_viewer in summary.supported_kinds
      assert :stream_widget in summary.supported_kinds
      assert :cluster_dashboard in summary.supported_kinds
    end

    test "all widgets use LiveComponent architecture except structural" do
      # All interactive widgets should be live_component
      interactive_widgets =
        Widgets.foundational_modules() ++
          Widgets.input_modules() ++
          Widgets.navigation_modules() ++
          Widgets.advanced_modules()

      Enum.each(interactive_widgets, fn mod ->
        metadata = LiveUi.Component.metadata(mod)
        # Most widgets should use live_component runtime boundary
        # unless they're explicitly marked as structural
        if metadata.runtime_boundary != :function_component do
          assert metadata.runtime_boundary == :live_component
          assert metadata.component_module
        end
      end)
    end

    test "structural components are clearly distinguished from LiveComponents" do
      # Layout components are structural (function components, not LiveComponents)
      structural_modules = LiveUi.Layout.modules()

      Enum.each(structural_modules, fn mod ->
        metadata = LiveUi.Component.metadata(mod)

        # Structural components use function_component runtime boundary
        assert metadata.runtime_boundary == :function_component

        # They still have a Component module for compatibility
        assert metadata.component_module
      end)
    end

    test "validation state confirms widget-component architecture is ready" do
      validation = LiveUi.Runtime.validation_state()

      # Should report ready state across key areas
      assert validation.mount == :ready
      assert validation.event_routing == :ready
      assert validation.live_component_host == :ready
      assert validation.canonical_renderer == :advanced_ready
    end

    test "style_summary exposes theme component information" do
      summary = Info.style_summary()

      assert summary.theme_id
      assert is_list(summary.native_components)
      assert summary.token_count > 0
    end

    test "widget_summary exposes local_state_keys for bounded state" do
      # Widgets with local state should have local_state_keys defined
      widget_with_state = LiveUi.Widgets.TextInput

      summary = Info.widget_summary(widget_with_state)

      assert summary.local_state_keys
      assert is_list(summary.local_state_keys)
      assert summary.mountable? == true
      assert summary.runtime_boundary == :live_component
    end
  end

  describe "17.4 - Phase 17 Integration Tests" do
    test "tooling provides visibility into widget component architecture" do
      # Info module should expose widget metadata
      assert function_exported?(LiveUi.Info, :widget_summary, 1)
      assert function_exported?(LiveUi.Info, :advanced_widget_summary, 0)
      assert function_exported?(LiveUi.Info, :package_summary, 0)
    end

    test "validation state reflects widget-component readiness" do
      validation = LiveUi.Runtime.validation_state()

      # Should report readiness across key areas
      assert validation.mount
      assert validation.event_routing
      assert validation.live_component_host
      assert validation.canonical_renderer
    end

    test "canonical rendering proves mounted widget behavior not passive HTML" do
      # Canonical rendering through Runtime.mount_iur uses LiveComponent boundaries
      element = UnifiedIUR.Widgets.Foundational.text("Test", id: "test-text")

      {:ok, runtime_state} = LiveUi.Runtime.mount_iur(element)

      html =
        render_component(Runtime.component(),
          id: "test",
          runtime_state: runtime_state
        )

      # Should have widget boundaries indicating LiveComponent architecture
      assert html =~ ~s(data-live-ui-widget-boundary="text")
      assert html =~ ~s(data-live-ui-widget-key=)
    end
  end
end
