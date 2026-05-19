defmodule AshUI.Phase33DocsConformanceTest do
  use ExUnit.Case, async: true

  @moduletag :conformance

  @repo_root Path.expand("../..", __DIR__)

  test "user and developer guides document canonical workflow progress status cards" do
    user_guide = read!("guides/user/UG-0003-widget-types-properties-and-signals.md")
    developer_guide = read!("guides/developer/DG-0003-compiler-canonical-iur-and-renderers.md")

    assert user_guide =~ "`workflow_progress_status_card`"
    assert user_guide =~ "`attributes.subject`"
    assert user_guide =~ "application-specific card names"

    assert developer_guide =~ "`attributes.subject`"
    assert developer_guide =~ "include the renderer"
    assert developer_guide =~ "element id, component kind, and component family"
    assert developer_guide =~ "Do not add route helpers"
  end

  test "canonical examples cover health, dependencies, actions, and signal previews" do
    examples = read!("examples/canonical_widget_components.md")

    assert examples =~ "type(:workflow_progress_status_card)"
    assert examples =~ "workflow_health_card"
    assert examples =~ "release_readiness_card"
    assert examples =~ "depends_on"
    assert examples =~ "depended_by"
    assert examples =~ "open_action"
    assert examples =~ "UnifiedIUR.Interaction.focus"
    assert examples =~ "UnifiedIUR.Interaction.selection"
    assert examples =~ "UnifiedIUR.Interaction.open"
    refute examples =~ "repo_progress_card"
  end

  defp read!(path) do
    @repo_root
    |> Path.join(path)
    |> File.read!()
  end
end
