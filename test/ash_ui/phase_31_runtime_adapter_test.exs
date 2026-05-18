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
  end

  describe "Section 31.4b - needs_you_section + blocker_row adapter dispatch" do
    test "LiveUIAdapter renders needs_you_section fallback preserving section semantics" do
      assert {:ok, canonical} =
               IUR.new(:needs_you_section,
                 id: "nys-adapter-test",
                 props: %{title: "Needs you", empty_state_text: "All clear", max_visible: 5}
               )
               |> IURAdapter.to_canonical()

      assert canonical.kind == :needs_you_section
      assert canonical.attributes.component.family == :workflow_progress_and_status
      assert canonical.attributes.section.title == "Needs you"
      assert canonical.attributes.section.empty_state_text == "All clear"

      assert {:ok, heex} = LiveUIAdapter.render(canonical, force_fallback: true)
      assert heex =~ "ash-needs-you-section"
      assert heex =~ "Needs you"
      assert heex =~ "All clear"
    end

    test "LiveUIAdapter renders blocker_row fallback preserving row semantics" do
      assert {:ok, canonical} =
               IUR.new(:blocker_row,
                 id: "br-adapter-test",
                 props: %{
                   row_id: "br-a1",
                   ask_text: "Approve the plan",
                   scope_label: "repo: ariston-ui",
                   severity: :warn,
                   actor: %{initials: "PC", actor_name: "Pascal"}
                 }
               )
               |> IURAdapter.to_canonical()

      assert canonical.kind == :blocker_row
      assert canonical.attributes.component.family == :row_and_artifact
      assert canonical.attributes.blocker.ask_text == "Approve the plan"
      assert canonical.attributes.blocker.severity == :warn

      assert {:ok, heex} = LiveUIAdapter.render(canonical, force_fallback: true)
      assert heex =~ "ash-blocker-row"
      assert heex =~ "Approve the plan"
      assert heex =~ "repo: ariston-ui"
      assert heex =~ ~s(aria-label="Approve the plan — repo: ariston-ui")
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
