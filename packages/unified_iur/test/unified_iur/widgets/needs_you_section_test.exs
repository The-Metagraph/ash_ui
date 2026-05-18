defmodule UnifiedIUR.Widgets.NeedsYouSectionTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Element
  alias UnifiedIUR.Widgets.Components

  describe "needs_you_section/2" do
    test "builds element with correct kind and family" do
      section = Components.needs_you_section([])

      assert %Element{kind: :needs_you_section} = section

      assert section.attributes.component == %{
               family: :workflow_progress_and_status,
               kind: :needs_you_section
             }
    end

    test "applies default section attributes" do
      section = Components.needs_you_section([])

      assert section.attributes.section == %{
               title: "Needs you",
               empty_state_text: "You're all caught up.",
               max_visible: 5
             }
    end

    test "accepts custom title, empty_state_text, and max_visible" do
      section =
        Components.needs_you_section([],
          title: "Review required",
          empty_state_text: "Nothing here.",
          max_visible: 3
        )

      assert section.attributes.section == %{
               title: "Review required",
               empty_state_text: "Nothing here.",
               max_visible: 3
             }
    end

    test "accepts blocker_row children and wraps them in default slot" do
      row1 =
        Components.blocker_row(row_id: "br-1", ask_text: "Decide X", scope_label: "doc: plan")

      row2 = Components.blocker_row(row_id: "br-2", ask_text: "Review Y", scope_label: "repo: ui")

      section = Components.needs_you_section([row1, row2])

      assert length(section.children) == 2
      assert Enum.all?(section.children, &(&1.slot == :default))
      assert Enum.all?(section.children, &match?(%{element: %Element{kind: :blocker_row}}, &1))
    end

    test "accepts id and accessibility opts" do
      section =
        Components.needs_you_section([],
          id: "attention-band",
          accessibility_label: "Needs your attention"
        )

      assert section.id == "attention-band"
      assert section.attributes.accessibility == %{label: "Needs your attention"}
    end

    test "empty items list is valid" do
      assert %Element{kind: :needs_you_section, children: []} = Components.needs_you_section([])
    end
  end

  describe "blocker_row/1" do
    test "builds element with correct kind and family" do
      row = Components.blocker_row(row_id: "r1", ask_text: "Act on this", scope_label: "doc: x")

      assert %Element{kind: :blocker_row} = row
      assert row.attributes.component == %{family: :row_and_artifact, kind: :blocker_row}
    end

    test "captures required blocker attributes" do
      row =
        Components.blocker_row(
          row_id: "br-abc",
          ask_text: "Please review the plan",
          scope_label: "doc: master-plan.md"
        )

      assert row.attributes.blocker.row_id == "br-abc"
      assert row.attributes.blocker.ask_text == "Please review the plan"
      assert row.attributes.blocker.scope_label == "doc: master-plan.md"
    end

    test "defaults severity to :info and scope_intent to jump_to_blocker" do
      row = Components.blocker_row(row_id: "r1", ask_text: "Act", scope_label: "x")

      assert row.attributes.blocker.severity == :info
      assert row.attributes.blocker.scope_intent == "jump_to_blocker"
    end

    test "accepts severity :warn" do
      row =
        Components.blocker_row(
          row_id: "r2",
          ask_text: "Urgent",
          scope_label: "doc: z",
          severity: :warn
        )

      assert row.attributes.blocker.severity == :warn
    end

    test "accepts severity :critical" do
      row =
        Components.blocker_row(
          row_id: "r3",
          ask_text: "Critical",
          scope_label: "doc: z",
          severity: :critical
        )

      assert row.attributes.blocker.severity == :critical
    end

    test "accepts scope_value override" do
      row =
        Components.blocker_row(
          row_id: "r4",
          ask_text: "Act",
          scope_label: "thread: discussion",
          scope_value: "thread-uuid-123"
        )

      assert row.attributes.blocker.scope_value == "thread-uuid-123"
    end

    test "accepts actor map with initials and actor_name" do
      row =
        Components.blocker_row(
          row_id: "r5",
          ask_text: "Act",
          scope_label: "doc: plan",
          actor: %{initials: "PC", actor_name: "Pascal", image_source: nil}
        )

      assert row.attributes.actor == %{initials: "PC", actor_name: "Pascal", image_source: nil}
    end

    test "omits actor attribute when not provided" do
      row = Components.blocker_row(row_id: "r6", ask_text: "Act", scope_label: "x")

      refute Map.has_key?(row.attributes, :actor)
    end
  end

  describe "kind registration" do
    test "needs_you_section is in workflow_kinds" do
      assert :needs_you_section in Components.workflow_kinds()
    end

    test "blocker_row is in row_artifact_kinds" do
      assert :blocker_row in Components.row_artifact_kinds()
    end

    test "both kinds are in the combined kinds/0 list" do
      all_kinds = Components.kinds()
      assert :needs_you_section in all_kinds
      assert :blocker_row in all_kinds
    end
  end
end
