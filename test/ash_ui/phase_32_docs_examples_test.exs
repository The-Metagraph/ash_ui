defmodule AshUI.Phase32DocsExamplesTest do
  use ExUnit.Case, async: true

  @moduletag :conformance

  @repo_root Path.expand("../..", __DIR__)

  test "user guides document right rail authoring and document composition boundary" do
    widget_guide = read!("guides/user/UG-0003-widget-types-properties-and-signals.md")
    composition_guide = read!("guides/user/UG-0007-data-surfaces-and-composition-patterns.md")

    assert widget_guide =~ "`right_rail` is the reusable rail component"
    assert widget_guide =~ "`panels`"
    assert widget_guide =~ "`active_panel`"
    assert widget_guide =~ "`collapsed?` and `collapsible?`"
    assert widget_guide =~ "`content_slot`"
    assert widget_guide =~ "do not introduce `doc_right_rail`"
    assert widget_guide =~ "| `right_rail` | `:change`, `:toggle`, `:click` |"

    assert composition_guide =~ "## Pattern 6: Reusable Right Rail Inspectors"
    assert composition_guide =~ "type(:right_rail)"
    assert composition_guide =~ "slot(:summary_body)"
    assert composition_guide =~ "`doc_right_rail` may be an application-local composition name"
  end

  test "developer guide documents rail package boundary and renderer support" do
    guide = read!("guides/developer/DG-0003-compiler-canonical-iur-and-renderers.md")

    assert guide =~ "`:rail`"
    assert guide =~ "`right_rail` is the canonical reusable rail component"
    assert guide =~ "`UnifiedIUR.Widgets.Components.right_rail/1`"
    assert guide =~ "`attributes.rail`"
    assert guide =~ "`doc_right_rail`"
    assert guide =~ "Live UI renders `right_rail` natively"
    assert guide =~ "Elm UI and desktop adapters currently preserve"
  end

  test "canonical component examples include reusable and document rail compositions" do
    examples = read!("examples/canonical_widget_components.md")

    assert examples =~ "## Reusable Right Rail"
    assert examples =~ "type(:right_rail)"
    assert examples =~ "workspace_inspector_rail"
    assert examples =~ "DocumentContextRail"
    assert examples =~ "document_context_rail"
    assert examples =~ "disabled?: true"
    assert examples =~ "badge: \"3\""
    assert examples =~ "empty_state: \"No sources available\""
    assert examples =~ "UnifiedIUR.Interaction.selection"
    assert examples =~ "UnifiedIUR.Interaction.change"
    refute examples =~ "type(:doc_right_rail)"
  end

  defp read!(path) do
    @repo_root
    |> Path.join(path)
    |> File.read!()
  end
end
