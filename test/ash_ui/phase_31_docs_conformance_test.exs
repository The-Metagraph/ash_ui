defmodule AshUI.Phase31DocsConformanceTest do
  use ExUnit.Case, async: true

  @moduletag :conformance

  @repo_root Path.expand("../..", __DIR__)

  test "user guides document canonical component names, aliases, and custom boundary" do
    guide = read!("guides/user/UG-0003-widget-types-properties-and-signals.md")
    migration = read!("guides/user/UG-0008-migration-from-older-ash-ui-models.md")

    for kind <- AshUI.WidgetComponents.kinds() do
      assert guide =~ Atom.to_string(kind)
    end

    assert guide =~ "phoenix_form"
    assert guide =~ "ui_relationship_repeat"
    assert guide =~ "Do not use `custom:*` for a component listed in the canonical catalog"
    assert migration =~ "`phoenix_form` becomes `runtime_form_shell`"

    assert migration =~
             "replace older custom component names with canonical widget-component names"
  end

  test "developer guides document catalog ownership, validation, and fallback behavior" do
    guide = read!("guides/developer/DG-0003-compiler-canonical-iur-and-renderers.md")

    assert guide =~ "AshUI.WidgetComponents"
    assert guide =~ "UnifiedUi.WidgetComponents"
    assert guide =~ "UnifiedIUR.Normalize.element/1"
    assert guide =~ "UnifiedIUR.Validate.element/1"
    assert guide =~ "structured fallback diagnostics"
    assert guide =~ "theme-owned tokens"
    assert guide =~ "`list_repeat` is the exception"
  end

  test "examples cover component families and relationship-owned list repeat" do
    examples = read!("examples/canonical_widget_components.md")

    for {_family, kinds} <- AshUI.WidgetComponents.families() do
      assert Enum.any?(kinds, &(examples =~ Atom.to_string(&1)))
    end

    assert examples =~ "type(:runtime_form_shell)"
    assert examples =~ "type(:artifact_row)"
    assert examples =~ "type(:code_block_syntax_highlighted)"
    assert examples =~ "relationship :artifact_rows"
    assert examples =~ "repeat(%{binding: :artifact_rows"
  end

  defp read!(path) do
    @repo_root
    |> Path.join(path)
    |> File.read!()
  end
end
