defmodule DesktopUi.ContinuityTest do
  use ExUnit.Case, async: true

  test "native and canonical continuity stays aligned through shared style and platform semantics" do
    assert {:ok, native_state} =
             DesktopUi.Runtime.mount_native_screen(
               DesktopUi.Examples.native_foundational_screen(),
               platform_target: :linux
             )

    assert {:ok, canonical_state} =
             DesktopUi.Runtime.mount_iur_screen(
               DesktopUi.Examples.canonical_foundational_screen(),
               platform_target: :linux
             )

    report = DesktopUi.Continuity.compare(native_state, canonical_state)

    assert report.continuity.widget_identity_match?
    assert report.continuity.style_resolution_match?
    assert report.continuity.platform_semantics_match?
    assert report.continuity.validation.status == :pass
    assert report.diagnostics == []
  end

  test "cross-target continuity keeps variation bounded under one shared contract" do
    assert {:ok, report} =
             DesktopUi.Continuity.compare_targets(DesktopUi.Examples.native_foundational_screen())

    assert report.continuity.widget_identity_match?
    assert report.continuity.style_resolution_match?
    assert report.continuity.platform_semantics_match?
    assert report.continuity.validation.status == :pass
    assert report.targets.windows.platform.artifacts.packaging == [:zip_archive, :msi_installer]
    assert report.targets.macos.platform.profile.integration.menus.scope == :application
  end
end
