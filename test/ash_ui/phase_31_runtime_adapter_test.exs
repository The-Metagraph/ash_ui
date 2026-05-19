defmodule AshUI.Phase31RuntimeAdapterTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias AshUI.Compilation.IUR
  alias AshUI.Rendering.{DesktopUIAdapter, ElmUIAdapter, IURAdapter, LiveUIAdapter}

  @moduletag :conformance

  describe "Section 31.4 - runtime renderer adapter support" do
    test "runtime packages advertise support for canonical widget component kinds" do
      component_kinds = AshUI.WidgetComponents.kinds()

      assert Enum.all?(component_kinds, &(&1 in LiveUi.Renderer.supported_kinds()))
      assert Enum.all?(component_kinds, &(&1 in ElmUi.Renderer.supported_kinds()))
      assert Enum.all?(component_kinds, &(&1 in DesktopUi.Renderer.supported_kinds()))
    end

    test "native Elm and desktop renderers preserve representative component identity" do
      component = canonical_component()

      assert {:ok, %ElmUi.Widget{} = elm_widget} = ElmUi.Renderer.render(component)
      assert elm_widget.kind == :event_callout
      assert elm_widget.metadata.unsupported_native_component == :fallback

      assert {:ok, %DesktopUi.Widget{} = desktop_widget} = DesktopUi.Renderer.render(component)
      assert desktop_widget.kind == :event_callout
      assert desktop_widget.metadata.unsupported_native_component == :fallback
    end

    test "Live native renderer exposes a structured component fallback diagnostic" do
      component = canonical_component()

      html =
        render_component(&LiveUi.Renderer.render/1,
          element: component,
          runtime_state: nil,
          event_target: nil
        )

      assert html =~ "data-live-ui-component-kind=\"event_callout\""
      assert html =~ "data-live-ui-unsupported-native-component=\"fallback\""
    end

    test "Ash fallback renderers preserve component identity and escape component text" do
      canonical = canonical_screen()

      assert {:ok, heex} = LiveUIAdapter.render(canonical, force_fallback: true)
      assert heex =~ "ash-event-callout"
      assert heex =~ "&lt;script&gt;alert(&#39;x&#39;)&lt;/script&gt;"
      refute heex =~ "<script>alert"

      assert {:ok, html} = ElmUIAdapter.render(canonical, force_fallback: true)
      assert html =~ "event_callout"

      assert {:ok, instructions} = DesktopUIAdapter.render(canonical, force_fallback: true)
      [widget] = instructions["content"]
      assert widget["widget_type"] == "event_callout"
      assert widget["diagnostic"]["code"] == "unsupported_component_fallback"
      assert widget["diagnostic"]["component_kind"] == :event_callout
    end

    test "IUR adapter routes confidence_indicator props into baseline feedback attributes" do
      assert {:ok, canonical} =
               IUR.new(:confidence_indicator,
                 id: "ci-test",
                 props: %{
                   value: 0.87,
                   thresholds: %{warn: 0.5, pass: 0.8},
                   label: "Match confidence"
                 }
               )
               |> IURAdapter.to_canonical()

      assert canonical.kind == :confidence_indicator
      assert canonical.type == :widget
      assert %{confidence: confidence} = canonical.attributes
      assert confidence.value == 0.87
      assert confidence.thresholds == %{warn: 0.5, pass: 0.8}
      assert confidence.label == "Match confidence"
      refute Map.has_key?(canonical.attributes, :component)
    end

    test "live_ui_adapter fallback renders confidence_indicator with meter semantics" do
      assert {:ok, canonical} =
               IUR.new(:screen,
                 id: "ci-screen",
                 name: "ci_test",
                 children: [
                   IUR.new(:confidence_indicator,
                     id: "ci-1",
                     props: %{
                       value: 0.87,
                       thresholds: %{warn: 0.5, pass: 0.8},
                       show_glyph?: false,
                       show_numeric?: false
                     }
                   )
                 ]
               )
               |> IURAdapter.to_canonical()

      assert {:ok, heex} = LiveUIAdapter.render(canonical, force_fallback: true)
      assert heex =~ "ash-confidence-indicator"
      assert heex =~ ~s(data-confidence-band="pass")
      assert heex =~ ~s(role="meter")
      assert heex =~ ~s(aria-valuenow="87")
      refute heex =~ "ash-confidence-indicator__glyph"
      refute heex =~ "ash-confidence-indicator__numeric"
    end
  end

  defp canonical_component do
    assert {:ok, canonical} =
             IUR.new(:event_callout,
               id: "callout-1",
               props: %{
                 message: "<script>alert('x')</script>",
                 tone: :warning
               }
             )
             |> IURAdapter.to_canonical()

    canonical
  end

  defp canonical_screen do
    assert {:ok, canonical} =
             IUR.new(:screen,
               id: "phase-31-screen",
               name: "phase_31",
               children: [
                 IUR.new(:event_callout,
                   id: "callout-1",
                   props: %{
                     message: "<script>alert('x')</script>",
                     tone: :warning
                   }
                 )
               ]
             )
             |> IURAdapter.to_canonical()

    canonical
  end
end
