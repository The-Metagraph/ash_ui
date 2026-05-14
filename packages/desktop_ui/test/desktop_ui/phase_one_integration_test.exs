defmodule DesktopUi.PhaseOneIntegrationTest do
  use ExUnit.Case, async: true

  alias DesktopUi.Runtime.Error
  alias UnifiedIUR.Element

  test "package exposes phase one entrypoints without application takeover" do
    assert DesktopUi.widgets() == DesktopUi.Widgets
    assert DesktopUi.widget() == DesktopUi.Widget
    assert DesktopUi.runtime() == DesktopUi.Runtime
    assert DesktopUi.platform() == DesktopUi.Platform
    assert DesktopUi.renderer() == DesktopUi.Renderer
    assert DesktopUi.transport() == DesktopUi.Transport
    assert DesktopUi.artifacts() == DesktopUi.Artifacts
    assert DesktopUi.tooling() == DesktopUi.Tooling
    assert DesktopUi.Renderer.accepts() == Element
    refute Keyword.has_key?(DesktopUi.MixProject.application(), :mod)
  end

  test "minimal native screens boot through the shared runtime backbone" do
    root =
      DesktopUi.Widgets.window("workspace-window", "Workspace", [
        DesktopUi.Widgets.column("workspace-column", [
          DesktopUi.Widgets.text("workspace-title", "Workspace"),
          DesktopUi.Widgets.button("save-workspace", "Save", intent: :save_workspace)
        ])
      ])

    screen = %{id: "workspace", title: "Workspace", root: root}

    assert {:ok, state} = DesktopUi.Runtime.mount_native_screen(screen, platform_target: :linux)
    assert state.runtime_id == "desktop-ui:workspace"
    assert state.screen_id == "workspace"
    assert state.source_kind == :native
    assert state.platform_target == :linux
    assert state.platform_adapter.target == :linux
    assert state.windows.primary == "window:workspace"
    assert state.realization.mode == :shared_sdl_runtime
    assert state.validation_state == :runtime_backbone_ready
    assert state.realization.validation_state == :foundational_ready
    assert state.event_loop.poller.source == :sdl_event_queue
    assert state.event_loop.frame.present_mode == :shared_runtime
  end

  test "malformed widgets and broken platform adapter registration fail with deterministic diagnostics" do
    assert {:error, %Error{} = invalid_root_error} =
             DesktopUi.Runtime.mount_native_screen(%{
               id: "broken",
               title: "Broken",
               root: %{label: "missing kind"}
             })

    assert invalid_root_error.reason == :invalid_screen_root
    assert invalid_root_error.phase == :runtime_boot

    valid_screen = %{
      id: "screen",
      title: "Screen",
      root: DesktopUi.Widgets.window("root", "Screen")
    }

    assert {:error, %Error{} = invalid_platform_error} =
             DesktopUi.Runtime.mount_native_screen(valid_screen, platform_target: :android)

    assert invalid_platform_error.reason == :unsupported_platform_target

    assert {:error, %Error{} = invalid_adapter_error} =
             DesktopUi.Runtime.mount_native_screen(valid_screen,
               platform_target: :linux,
               adapter_registry: %{linux: DesktopUi}
             )

    assert invalid_adapter_error.reason == :invalid_platform_adapter
  end

  test "reference helpers and inspection surfaces expose runtime and platform seams before canonical coverage exists" do
    reference = DesktopUi.reference()
    summary = DesktopUi.info()

    assert reference.widgets.validation_state.direct_native_scaffold == :ready
    assert reference.runtime.validation_state == :runtime_backbone_ready
    assert reference.platform.validation_state == :platform_adapter_ready
    assert reference.platform.targets == [:windows, :macos, :linux]

    assert reference.transport.integration_points == [
             :runtime,
             :platform_input_normalization,
             :canonical_signal_translation,
             :transport_diagnostics
           ]

    assert reference.inspection.package_overview.runtime_foundation == :sdl3
    assert reference.inspection.package_overview.runtime_binding == :sdl
    assert reference.inspection.sdl3_adapter_surface.foundation.runtime_foundation == :sdl3
    assert reference.inspection.validation_surface.transport == :transport_diagnostics_ready
    assert reference.inspection.validation_surface.sdl3 == :app_handoff_ready
    assert reference.responsibilities.bounded_platform_variation

    assert summary.package == :desktop_ui
    assert summary.runtime.validation_state == :runtime_backbone_ready
    assert :window in summary.widgets.families
    assert :window in summary.widgets.kinds
    assert summary.inspection.validation.runtime == :runtime_backbone_ready
  end

  test "shared runtime semantics remain visible through package-facing helper APIs" do
    contract = DesktopUi.Inspection.shared_runtime_contract()

    assert contract.assumptions.shared_runtime_foundation == :sdl3
    assert contract.lifecycle_model == :callback_oriented
    assert contract.direct_native_and_canonical_share_runtime

    assert DesktopUi.Reference.package_reference().inspection.shared_runtime_contract ==
             contract

    assert DesktopUi.Runtime in contract.runtime_modules
    assert DesktopUi.Sdl3 in contract.sdl3_modules
    assert :native_mount in DesktopUi.Runtime.capabilities()
  end
end
