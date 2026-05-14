defmodule DesktopUi.InspectionTest do
  use ExUnit.Case, async: true

  test "runtime snapshots expose effective style nodes and platform profiles" do
    assert {:ok, state} =
             DesktopUi.Runtime.mount_native_screen(
               DesktopUi.Examples.native_foundational_screen(),
               platform_target: :linux
             )

    snapshot = DesktopUi.Inspection.runtime_snapshot(state)

    assert snapshot.runtime.platform_target == :linux
    assert snapshot.style.theme == :desktop_default
    assert snapshot.style.node_count > 0
    assert Enum.any?(snapshot.style.style_nodes, &(&1.id == "workspace-window"))
    assert snapshot.platform.profile.target == :linux
    assert snapshot.platform.artifacts.packaging == [:tar_archive, :appimage_like_bundle]
    assert Enum.any?(DesktopUi.Inspection.helpers(), &(&1 == :runtime_snapshot))
    assert Enum.any?(DesktopUi.Inspection.helpers(), &(&1 == :packaging_contract))
    assert DesktopUi.Inspection.continuity_contract().validation == [:pass, :fail]

    assert DesktopUi.Inspection.package_overview().packaging.validation_state ==
             :target_packaging_surface_ready
  end
end
