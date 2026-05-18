defmodule LiveUi.NeedsYouSectionTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Component
  alias UnifiedIUR.Widgets.Components

  describe "NeedsYouSection widget component" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.NeedsYouSection)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.NeedsYouSection.Component
      assert metadata.name == :needs_you_section
    end

    test "renders with needs-you-section widget marker" do
      html =
        render_component(&LiveUi.Widgets.NeedsYouSection.component/1, %{
          id: "attention-band",
          items: [],
          event_target: nil
        })

      assert html =~ ~s(data-live-ui-widget="needs-you-section")
      assert html =~ "Needs you"
      assert html =~ "You&#39;re all caught up."
    end

    test "renders empty-state message when no items" do
      html =
        render_component(&LiveUi.Widgets.NeedsYouSection.component/1, %{
          id: "attention-band",
          items: [],
          event_target: nil
        })

      assert html =~ "You&#39;re all caught up."
      refute html =~ "<ul"
    end

    test "renders custom title and empty_state_text" do
      html =
        render_component(&LiveUi.Widgets.NeedsYouSection.component/1, %{
          id: "custom-band",
          title: "Action required",
          empty_state_text: "All clear!",
          items: [],
          event_target: nil
        })

      assert html =~ "Action required"
      assert html =~ "All clear!"
    end

    test "renders item list when items are present" do
      # Use a rendered element as a dummy item
      section_element =
        Components.needs_you_section(
          [
            Components.blocker_row(
              row_id: "br-1",
              ask_text: "Decide on plan",
              scope_label: "doc: master-plan.md",
              actor: %{initials: "PC", actor_name: "Pascal"}
            )
          ],
          id: "band-1"
        )

      html = render_component(&LiveUi.Renderer.render/1, %{element: section_element})

      assert html =~ ~s(data-live-ui-widget="needs-you-section")
      assert html =~ "<ul"
      assert html =~ "Decide on plan"
    end

    test "renders item count when items are present" do
      row1 =
        Components.blocker_row(
          row_id: "c1",
          ask_text: "Act",
          scope_label: "doc: x",
          actor: %{initials: "A", actor_name: "Alice"}
        )

      row2 =
        Components.blocker_row(
          row_id: "c2",
          ask_text: "Decide",
          scope_label: "repo: y",
          actor: %{initials: "B", actor_name: "Bob"}
        )

      section_element =
        Components.needs_you_section([row1, row2], id: "count-band")

      html = render_component(&LiveUi.Renderer.render/1, %{element: section_element})

      assert html =~ "(2)"
    end

    test "overflow count shows more button when items exceed max_visible" do
      # 4 blocker_row items with max_visible of 2 → show 2 more button
      rows =
        Enum.map(1..4, fn i ->
          Components.blocker_row(
            row_id: "overflow-#{i}",
            ask_text: "Act #{i}",
            scope_label: "doc: #{i}",
            actor: %{initials: "T#{i}", actor_name: "Tester #{i}"}
          )
        end)

      section_element =
        Components.needs_you_section(rows, id: "overflow-band", max_visible: 2)

      html = render_component(&LiveUi.Renderer.render/1, %{element: section_element})

      assert html =~ "show 2 more"
      assert html =~ "live-ui-needs-you__more"
    end

    test "no more button when items fit within max_visible" do
      rows =
        Enum.map(1..3, fn i ->
          Components.blocker_row(
            row_id: "fit-#{i}",
            ask_text: "Act #{i}",
            scope_label: "doc: #{i}",
            actor: %{initials: "T#{i}", actor_name: "Tester #{i}"}
          )
        end)

      section_element =
        Components.needs_you_section(rows, id: "no-overflow-band", max_visible: 5)

      html = render_component(&LiveUi.Renderer.render/1, %{element: section_element})

      refute html =~ "show"
      refute html =~ "live-ui-needs-you__more"
    end
  end

  describe "BlockerRow widget component" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.BlockerRow)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.BlockerRow.Component
      assert metadata.name == :blocker_row
    end

    test "renders with blocker-row widget marker" do
      html =
        render_component(&LiveUi.Widgets.BlockerRow.component/1, %{
          id: "row-1",
          row_id: "br-abc",
          ask_text: "Review the plan",
          scope_label: "doc: master-plan.md",
          severity: "info",
          actor: %{initials: "PC", actor_name: "Pascal"}
        })

      assert html =~ ~s(data-live-ui-widget="blocker-row")
      assert html =~ ~s(data-row-id="br-abc")
      assert html =~ ~s(data-severity="info")
    end

    test "renders ask_text and scope_label in body" do
      html =
        render_component(&LiveUi.Widgets.BlockerRow.component/1, %{
          id: "row-2",
          row_id: "br-body",
          ask_text: "Needs a decision on X",
          scope_label: "repo: ariston-ui",
          severity: "info",
          actor: %{initials: "MJ", actor_name: "Matt"}
        })

      assert html =~ "Needs a decision on X"
      assert html =~ "repo: ariston-ui"
    end

    test "includes aria-label from ask_text and scope_label" do
      html =
        render_component(&LiveUi.Widgets.BlockerRow.component/1, %{
          id: "row-3",
          row_id: "br-aria",
          ask_text: "Review spec",
          scope_label: "doc: spec.md",
          severity: "warn",
          actor: %{initials: "PC", actor_name: "Pascal"}
        })

      assert html =~ ~s(aria-label="Review spec — doc: spec.md")
    end

    test "applies severity modifier class" do
      html =
        render_component(&LiveUi.Widgets.BlockerRow.component/1, %{
          id: "row-4",
          row_id: "br-crit",
          ask_text: "Blocking",
          scope_label: "repo: metagraph",
          severity: "critical",
          actor: %{initials: "MJ", actor_name: "Matt"}
        })

      assert html =~ "live-ui-blocker-row--critical"
      assert html =~ ~s(data-severity="critical")
    end

    test "renders initials when no image_source" do
      html =
        render_component(&LiveUi.Widgets.BlockerRow.component/1, %{
          id: "row-5",
          row_id: "br-init",
          ask_text: "Act",
          scope_label: "doc: x",
          severity: "info",
          actor: %{initials: "AB", actor_name: "Alice"}
        })

      assert html =~ "AB"
      refute html =~ "<img"
    end

    test "renders via LiveUi.Renderer for round-trip smoke check" do
      element =
        Components.blocker_row(
          id: "smoke-row",
          row_id: "br-smoke",
          ask_text: "Needs your input",
          scope_label: "doc: master-plan.md",
          severity: :warn,
          actor: %{initials: "PC", actor_name: "Pascal"}
        )

      html = render_component(&LiveUi.Renderer.render/1, %{element: element})

      assert html =~ ~s(data-live-ui-widget="blocker-row")
      assert html =~ "Needs your input"
      assert html =~ "doc: master-plan.md"
    end
  end
end
