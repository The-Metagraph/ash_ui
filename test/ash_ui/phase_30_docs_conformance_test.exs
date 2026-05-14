defmodule AshUI.Phase30DocsConformanceTest do
  use ExUnit.Case, async: true

  @moduletag :conformance

  @repo_root Path.expand("../..", __DIR__)

  test "user guides document canonical navigation authoring and forbidden host fields" do
    guide = read!("guides/user/UG-0004-bindings-actions-and-forms.md")

    assert guide =~ "Canonical Navigation Actions"
    assert guide =~ "ui_actions"
    assert guide =~ "ui_screen_actions"
    assert guide =~ ":navigate_to"
    assert guide =~ ":open_modal"
    assert guide =~ "route"
    assert guide =~ "modal_stack_id"
  end

  test "developer guides document canonical package and renderer boundaries" do
    guide = read!("guides/developer/DG-0003-compiler-canonical-iur-and-renderers.md")

    assert guide =~ "%UnifiedIUR.Element{}"
    assert guide =~ "LiveUi"
    assert guide =~ "ElmUi"
    assert guide =~ "DesktopUi"
    assert guide =~ "AshUI.Rendering.CanonicalIUR"
    assert guide =~ "Legacy string-keyed maps"
  end

  test "style intent guidance remains explicit in user and developer guides" do
    user_guide = read!("guides/user/UG-0003-widget-types-properties-and-signals.md")
    developer_guide = read!("guides/developer/DG-0003-compiler-canonical-iur-and-renderers.md")

    assert user_guide =~ "resource-authored semantic intent plus host-owned CSS"
    assert user_guide =~ "variants([:primary, :profile_action])"
    assert developer_guide =~ "resource DSL owns semantic style intent"
    assert developer_guide =~ "host applications own CSS tokens"
  end

  defp read!(path) do
    @repo_root
    |> Path.join(path)
    |> File.read!()
  end
end
