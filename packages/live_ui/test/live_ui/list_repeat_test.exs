defmodule LiveUi.ListRepeatTest do
  @moduledoc """
  Tests for Stage-4 ListRepeat Phoenix.Component (LiveUi.Widgets.ListRepeat)
  and the dedicated renderer clause in LiveUi.Renderer.

  Tests cover:
  - Stage-4 component: id/items required, data-repeat-binding emitted correctly,
    data-live-ui-widget present, no fallback marker
  - Empty list case: no row content rendered
  - Non-empty case with hydrated child elements via renderer path
  - Renderer dispatches to Stage-4 module (not @component_kinds fallback):
    no data-live-ui-unsupported-native-component="fallback" marker
  - Renderer emits repeat_binding from IUR element attributes
  - Renderer renders pre-hydrated child elements via :row slot
  """

  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Widgets.ListRepeat
  alias UnifiedIUR.Widgets.{Components, Foundational}

  # ---------------------------------------------------------------------------
  # Stage-4 Phoenix.Component direct render tests
  # ---------------------------------------------------------------------------

  test "component renders div with data-live-ui-widget=list-repeat and provided id" do
    html =
      render_component(&LiveUi.Widgets.ListRepeat.render/1, %{
        id: "repeat-test",
        items: [],
        repeat_binding: nil,
        tone: nil,
        variant: nil,
        state: nil,
        class: nil,
        rest: %{},
        metadata: %{},
        row: [],
        empty_state: []
      })

    assert html =~ ~s(id="repeat-test")
    assert html =~ ~s(data-live-ui-widget="list-repeat")
    refute html =~ ~s(data-live-ui-unsupported-native-component="fallback")
  end

  test "component emits data-repeat-binding when set" do
    html =
      render_component(&LiveUi.Widgets.ListRepeat.render/1, %{
        id: "repeat-binding",
        items: [],
        repeat_binding: "artifact_rows",
        tone: nil,
        variant: nil,
        state: nil,
        class: nil,
        rest: %{},
        metadata: %{},
        row: [],
        empty_state: []
      })

    assert html =~ ~s(data-repeat-binding="artifact_rows")
  end

  test "component does not emit data-repeat-binding when nil" do
    html =
      render_component(&LiveUi.Widgets.ListRepeat.render/1, %{
        id: "repeat-no-binding",
        items: [],
        repeat_binding: nil,
        tone: nil,
        variant: nil,
        state: nil,
        class: nil,
        rest: %{},
        metadata: %{},
        row: [],
        empty_state: []
      })

    # nil repeat_binding should not produce a non-empty data-repeat-binding attr value
    refute html =~ ~s(data-repeat-binding=")
  end

  # ---------------------------------------------------------------------------
  # Renderer dispatch tests (go through LiveUi.Renderer.render/1)
  # ---------------------------------------------------------------------------

  test "renderer dispatches :list_repeat to Stage-4 module, not @component_kinds fallback" do
    element = Components.list_repeat(nil, id: "renderer-dispatch-test")

    html = render_component(&LiveUi.Renderer.render/1, %{element: element})

    # Stage-4 dispatch: widget attr present
    assert html =~ ~s(data-live-ui-widget="list-repeat")
    # Fallback NOT used
    refute html =~ ~s(data-live-ui-unsupported-native-component="fallback")
    # Fallback component-kind attr NOT used
    refute html =~ ~s(data-live-ui-component-kind="list_repeat")
  end

  test "renderer emits repeat_binding from IUR element :repeat attributes" do
    element = Components.list_repeat(nil, id: "renderer-binding-test", repeat_binding: "users")

    html = render_component(&LiveUi.Renderer.render/1, %{element: element})

    assert html =~ ~s(data-repeat-binding="users")
  end

  test "renderer renders empty list without crashing" do
    element = Components.list_repeat(nil, id: "renderer-empty-test")

    html = render_component(&LiveUi.Renderer.render/1, %{element: element})

    assert html =~ ~s(data-live-ui-widget="list-repeat")
  end

  test "renderer renders pre-hydrated child elements via :row slot through canonical renderer" do
    # NOTE: The list_repeat constructor stores the template child under the
    # :template slot (Element.Child.new(:template, child)), NOT under :default.
    # The renderer's child_elements/2 call uses :default, so pre-hydration (the
    # IURHydration expand_list_repeat/1 pass) must produce :default-slotted
    # children before the renderer is reached. Without hydration, no row children
    # appear — this is the correct behavior and documents the Issue #114 coupling.
    #
    # To test hydrated rendering we construct the element directly with a
    # :default-slotted child, simulating what IURHydration produces.
    alias UnifiedIUR.Element

    child = Foundational.text("Row content", id: "child-text-1")

    # Build a list_repeat element with a :default-slotted child (post-hydration shape)
    element =
      Element.new(:composition_behavior, :list_repeat,
        id: "renderer-children-test",
        attributes: %{repeat: %{binding_id: "rows"}},
        children: [UnifiedIUR.Element.Child.new(:default, child)]
      )

    html = render_component(&LiveUi.Renderer.render/1, %{element: element})

    assert html =~ ~s(data-live-ui-widget="list-repeat")
    # :default-slotted child renders through the :row slot -> .render delegation
    assert html =~ ~s(data-live-ui-widget="text")
  end

  test "is exposed through the composition behavior widget family" do
    metadata = LiveUi.Component.metadata(ListRepeat)

    assert :composition_behavior in LiveUi.Widgets.families()
    assert ListRepeat in LiveUi.Widgets.CompositionBehavior.modules()
    assert ListRepeat in LiveUi.Widgets.composition_behavior_modules()
    assert ListRepeat in LiveUi.Widgets.modules()
    assert metadata.family == :composition_behavior
    assert metadata.name == :list_repeat
    assert :row in metadata.slots
    assert :empty_state in metadata.slots
  end
end
