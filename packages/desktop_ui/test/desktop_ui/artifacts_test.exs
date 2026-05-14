defmodule DesktopUi.ArtifactsTest do
  use ExUnit.Case, async: true

  test "artifact workflows stay explicit per target without redefining runtime semantics" do
    assert DesktopUi.Artifacts.target_platforms() == [:windows, :macos, :linux]

    assert DesktopUi.Artifacts.workflow(:windows).packaging == [:zip_archive, :msi_installer]
    assert DesktopUi.Artifacts.workflow(:macos).packaging == [:app_bundle, :signed_zip]
    assert DesktopUi.Artifacts.workflow(:linux).packaging == [:tar_archive, :appimage_like_bundle]

    assert DesktopUi.Artifacts.artifact_types(:windows) == [:portable_archive, :installer]
    assert DesktopUi.Artifacts.boundary_policy().shared_runtime_semantics
    assert DesktopUi.Artifacts.boundary_policy().packaging_distinct_from_runtime_logic
    assert DesktopUi.Artifacts.diagnostics().invalid_targets == []
    assert DesktopUi.Artifacts.validation_state().shared_semantics_preservation == :ready
  end
end
