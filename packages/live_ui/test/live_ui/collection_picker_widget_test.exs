defmodule LiveUi.CollectionPickerWidgetTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias UnifiedIUR.Widgets.Components

  describe "CollectionPicker Phoenix.Component" do
    test "is registered in the form-control component family" do
      metadata = LiveUi.Component.metadata(LiveUi.Widgets.CollectionPicker)

      assert LiveUi.Widgets.CollectionPicker in LiveUi.Widgets.FormControlAndComposer.modules()
      assert LiveUi.Widgets.CollectionPicker in LiveUi.Widgets.form_control_and_composer_modules()
      assert LiveUi.Widgets.CollectionPicker in LiveUi.Widgets.modules()
      assert metadata.family == :form_control_and_composer
      assert metadata.name == :collection_picker
      assert :change in metadata.events
      assert :selection in metadata.events
      assert :command in metadata.events
    end

    test "renders generic filters, items, and suggestions" do
      html =
        render_component(&LiveUi.Widgets.CollectionPicker.component/1, %{
          id: "source-picker",
          picker_id: "sources",
          title: "Sources",
          query: "adr",
          filters: [%{id: "all", label: "All", selected?: true, count: 2}],
          items: [%{id: "adr-1", label: "ADR 1", description: "Architecture decision"}],
          suggestions: [%{id: "suggestion-1", label: "Add ADR 2", source: "system"}]
        })

      assert html =~ ~s(data-live-ui-widget="collection-picker")
      assert html =~ ~s(data-picker-id="sources")
      assert html =~ ~s(value="adr")
      assert html =~ "Sources"
      assert html =~ "ADR 1"
      assert html =~ "Architecture decision"
      assert html =~ "Add ADR 2"
      assert html =~ "system"
      refute html =~ "bundle"
      refute html =~ ~s(data-live-ui-component-kind)
    end

    test "accepts renderer-supplied canonical interaction attrs" do
      html =
        render_component(&LiveUi.Widgets.CollectionPicker.component/1, %{
          id: "source-picker",
          picker_id: "sources",
          query_attrs: %{"phx-change": "canonical_change_interaction"},
          filters: [%{id: "all", label: "All"}],
          filter_attrs: %{"all" => %{"phx-click": "canonical_interaction"}},
          items: [%{id: "adr-1", label: "ADR 1"}],
          item_attrs: %{"adr-1" => %{"phx-click": "canonical_interaction"}},
          suggestions: [%{id: "suggestion-1", label: "Add ADR 2"}],
          suggestion_accept_attrs: %{
            "suggestion-1" => %{"phx-click": "canonical_interaction"}
          },
          suggestion_dismiss_attrs: %{
            "suggestion-1" => %{"phx-click": "canonical_interaction"}
          }
        })

      assert html =~ ~s(phx-change="canonical_change_interaction")
      assert html =~ ~s(phx-click="canonical_interaction")
      refute html =~ "on_search_change"
      refute html =~ "on_toggle_event"
    end
  end

  describe "LiveUi.Renderer integration" do
    test "dispatches canonical collection_picker through native component boundary" do
      element =
        Components.collection_picker(
          id: "source-picker",
          picker_id: "sources",
          query: "adr",
          filters: [%{id: "all", label: "All"}],
          items: [%{id: "adr-1", label: "ADR 1"}],
          suggestions: [%{id: "suggestion-1", label: "Add ADR 2"}]
        )

      html =
        render_component(&LiveUi.Renderer.render/1, %{
          element: element,
          event_target: "#runtime-host"
        })

      assert html =~ ~s(data-live-ui-widget="collection-picker")
      assert html =~ ~s(phx-change="canonical_change_interaction")
      assert html =~ ~s(phx-click="canonical_interaction")
      assert html =~ ~s(phx-target="#runtime-host")
      assert html =~ ~s(phx-value-widget="collection_picker")
      assert html =~ ~s(phx-value-item_id="adr-1")
      assert html =~ ~s(phx-value-filter_id="all")
      assert html =~ ~s(phx-value-suggestion_id="suggestion-1")
      refute html =~ ~s(data-live-ui-component-kind)
      refute html =~ "bundle_rail"
    end
  end
end
