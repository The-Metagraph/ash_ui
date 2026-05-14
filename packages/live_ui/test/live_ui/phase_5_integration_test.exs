defmodule LiveUi.Phase5IntegrationTest do
  use ExUnit.Case, async: true

  alias LiveUi.Examples.{
    CanonicalStyledOperations,
    CanonicalStyledProfile,
    NativeStyledOperationsScreen,
    NativeStyledProfileScreen,
    StyledContinuityComparison
  }

  test "styled native and canonical examples expose deterministic inspection snapshots" do
    assert {:ok, native_profile} = LiveUi.Tooling.inspect_native(NativeStyledProfileScreen)

    assert {:ok, canonical_profile} =
             LiveUi.Tooling.inspect_canonical(CanonicalStyledProfile.element())

    assert "box" in native_profile.widgets
    assert "text" in native_profile.widgets
    assert "text-input" in native_profile.widgets
    assert "button" in native_profile.widgets
    assert "success" in native_profile.tones
    assert "success" in canonical_profile.tones

    assert Enum.any?(
             native_profile.entries,
             &(&1.widget == "button" and &1.tone == "accent")
           )

    assert Enum.any?(
             canonical_profile.entries,
             &(&1.widget == "button" and &1.tone == "accent")
           )

    assert {:ok, native_operations} = LiveUi.Tooling.inspect_native(NativeStyledOperationsScreen)

    assert {:ok, canonical_operations} =
             LiveUi.Tooling.inspect_canonical(CanonicalStyledOperations.element())

    for widget <- ["overlay-surface", "viewport", "canvas", "dialog", "cluster-dashboard"] do
      assert widget in native_operations.widgets
      assert widget in canonical_operations.widgets
    end

    assert "muted" in native_operations.tones
    assert "muted" in canonical_operations.tones
  end

  test "styled continuity workflow keeps native and canonical outputs aligned" do
    assert {:ok, continuity} = StyledContinuityComparison.compare()

    assert continuity.profile.continuity.widgets_aligned?
    assert continuity.profile.continuity.tone_overlap?
    assert continuity.profile.continuity.runtime_model_aligned?
    assert continuity.profile.diagnostics == []

    assert continuity.operations.continuity.widgets_aligned?
    assert continuity.operations.continuity.tone_overlap?
    assert continuity.operations.continuity.runtime_model_aligned?
    assert continuity.operations.diagnostics == []

    assert continuity.profile.native.path == :native
    assert continuity.profile.canonical.path == :canonical
    assert continuity.operations.native.path == :native
    assert continuity.operations.canonical.path == :canonical

    assert continuity.boundary.native_local.signal == nil
    assert continuity.boundary.runtime_action.runtime_event == "rename"
  end

  test "inspection and continuity workflows stay package-facing and example-backed" do
    workflows = LiveUi.Tooling.workflows()
    examples = LiveUi.Tooling.examples()

    assert :styling_inspection in workflows
    assert :continuity_comparison in workflows

    assert Enum.any?(examples, &(&1.id == :button and &1.path == :aligned))
    refute Enum.any?(examples, &(&1.id == :styled_continuity_compare))

    assert {:ok, report} =
             LiveUi.Tooling.compare_native_and_canonical(
               NativeStyledOperationsScreen,
               CanonicalStyledOperations.element()
             )

    assert is_binary(report.native.html)
    assert is_binary(report.canonical.html)
    assert is_list(report.native.entries)
    assert is_list(report.canonical.entries)
    assert report.continuity.widgets_aligned?
    assert report.continuity.runtime_model_aligned?
  end
end
