defmodule DesktopUi.PhaseFiveIntegrationTest do
  use ExUnit.Case, async: true

  test "native and canonical styling resolve through one shared theme model" do
    native_screen = DesktopUi.Examples.native_foundational_screen()
    canonical_screen = DesktopUi.Examples.canonical_foundational_screen()

    assert {:ok, native_state} =
             DesktopUi.Runtime.mount_native_screen(native_screen, platform_target: :linux)

    assert {:ok, canonical_state} =
             DesktopUi.Runtime.mount_iur_screen(canonical_screen, platform_target: :linux)

    report = DesktopUi.Continuity.compare(native_state, canonical_state)
    reference = DesktopUi.reference()
    summary = DesktopUi.info()

    assert native_state.realization.theme == :desktop_default
    assert canonical_state.realization.theme == :desktop_default
    assert report.continuity.widget_identity_match?
    assert report.continuity.style_resolution_match?
    assert report.continuity.platform_semantics_match?
    assert report.continuity.validation.status == :pass
    assert reference.style.validation_state.direct_native_surface == :ready
    assert reference.theme.validation_state.shared_style_model == :ready
    assert summary.continuity.seams == [:widget_identity, :style_resolution, :platform_semantics]
  end

  test "platform-specific artifact workflows remain explicit without redefining shared semantics" do
    diagnostics = DesktopUi.Artifacts.diagnostics()
    reference = DesktopUi.reference()
    summary = DesktopUi.info()

    assert diagnostics.targets == [:windows, :macos, :linux]
    assert diagnostics.workflows.windows.packaging == [:zip_archive, :msi_installer]
    assert diagnostics.workflows.macos.packaging == [:app_bundle, :signed_zip]
    assert diagnostics.workflows.linux.packaging == [:tar_archive, :appimage_like_bundle]
    assert diagnostics.invalid_targets == []
    assert diagnostics.boundary_policy.shared_runtime_semantics
    assert diagnostics.boundary_policy.widget_semantics_preserved
    assert diagnostics.boundary_policy.transport_semantics_preserved
    assert reference.artifacts.validation_state.shared_semantics_preservation == :ready
    assert summary.artifacts.validation_state.workflow_catalog == :ready
  end

  test "cross-target continuity and inspection helpers surface bounded variation deterministically" do
    native_screen = DesktopUi.Examples.native_foundational_screen()

    assert {:ok, linux_state} =
             DesktopUi.Runtime.mount_native_screen(native_screen, platform_target: :linux)

    snapshot = DesktopUi.Inspection.runtime_snapshot(linux_state)

    assert {:ok, target_report} = DesktopUi.Continuity.compare_targets(native_screen)

    assert snapshot.runtime.platform_target == :linux
    assert snapshot.style.theme == :desktop_default
    assert snapshot.platform.profile.integration.notifications.surface == :desktop_portal
    assert snapshot.platform.artifacts.packaging == [:tar_archive, :appimage_like_bundle]
    assert target_report.continuity.widget_identity_match?
    assert target_report.continuity.style_resolution_match?
    assert target_report.continuity.platform_semantics_match?
    assert target_report.continuity.validation.status == :pass

    assert target_report.targets.windows.platform.profile.integration.windowing.chrome ==
             :native_frame

    assert target_report.targets.macos.platform.profile.integration.menus.scope == :application

    assert target_report.targets.linux.platform.profile.integration.notifications.surface ==
             :desktop_portal
  end
end
