defmodule AshUI.Phase33IntegrationTest do
  use ExUnit.Case, async: true

  alias AshUI.Compilation.IUR
  alias AshUI.Rendering.{DesktopUIAdapter, ElmUIAdapter, IURAdapter, LiveUIAdapter}
  alias UnifiedIUR.Validate

  @moduletag :conformance

  test "workflow_progress_status_card works across canonical conversion and renderer adapters" do
    ash_iur =
      IUR.new(:screen,
        id: "phase-33-workflow-screen",
        name: "phase_33_workflow_screen",
        children: [
          IUR.new(:workflow_progress_status_card,
            id: "phase-33-workflow-card",
            props: %{
              "subject_id" => "subject:release-readiness",
              "name" => "Release readiness",
              "path" => "workspaces/release-readiness",
              "progress_pct" => 0.84,
              "active_count" => 2,
              "blocked_count" => 1,
              "depends_on" => [
                %{"id" => "subject:unified_iur", "label" => "Unified IUR", "state" => "done"}
              ],
              "depended_by" => [
                %{"id" => "subject:live_ui", "label" => "Live UI", "state" => "blocked"}
              ],
              "selected?" => true,
              "focus_intent" => "focus_subject",
              "open_action" => %{
                "label" => "Open",
                "intent" => "open_subject",
                "visible_when" => :when_selected
              }
            }
          )
        ]
      )

    assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
    [%{element: card}] = canonical.children

    assert card.kind == :workflow_progress_status_card
    assert card.attributes.component.family == :workflow_progress_and_status
    assert card.attributes.subject.id == "subject:release-readiness"
    assert card.attributes.subject.progress == 84.0
    assert card.attributes.subject.status_counts == %{active: 2, blocked: 1}

    assert card.attributes.subject.dependencies.depends_on |> hd() |> Map.get(:id) ==
             "subject:unified_iur"

    refute Map.has_key?(card.attributes, :repo)
    assert :ok = Validate.element(card)

    assert {:ok, heex} = LiveUIAdapter.render(canonical, force_fallback: true)
    assert heex =~ ~s(data-subject-card="Release readiness")
    assert heex =~ ~s(role="progressbar")
    assert heex =~ "84"

    assert {:ok, elm_html} = ElmUIAdapter.render(card, force_fallback: true)
    assert elm_html =~ ~s(data-renderer="elm_ui")
    assert elm_html =~ ~s(data-component-id="phase-33-workflow-card")
    assert elm_html =~ ~s(data-component-kind="workflow_progress_status_card")

    assert {:ok, desktop_card} = DesktopUIAdapter.render(card, force_fallback: true)
    assert desktop_card["widget_type"] == "workflow_progress_status_card"
    assert desktop_card["diagnostic"]["renderer"] == "desktop_ui"
    assert desktop_card["diagnostic"]["element_id"] == "phase-33-workflow-card"
    assert desktop_card["diagnostic"]["component_kind"] == :workflow_progress_status_card
  end
end
