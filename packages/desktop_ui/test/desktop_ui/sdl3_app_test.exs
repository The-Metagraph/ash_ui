defmodule DesktopUi.Sdl3AppTest do
  use ExUnit.Case, async: true

  alias DesktopUi.Sdl3.{App, Lifecycle}

  test "native screens hand off into a callback-oriented SDL3 boot request" do
    screen = %{
      id: "workspace",
      title: "Workspace",
      root:
        DesktopUi.Widgets.window("workspace-window", "Workspace", [
          DesktopUi.Widgets.text("workspace-title", "Workspace"),
          DesktopUi.Widgets.button("save-button", "Save", intent: :save_workspace)
        ])
    }

    assert {:ok, boot_request} = App.boot_native_screen(screen, platform_target: :linux)

    assert boot_request.foundation == :sdl3
    assert boot_request.binding == :sdl
    assert boot_request.validation_state == :app_handoff_ready
    assert boot_request.runtime.runtime_id == "desktop-ui:workspace"
    assert boot_request.runtime.screen_id == "workspace"
    assert boot_request.runtime.source_kind == :native
    assert boot_request.runtime.direct_native_and_canonical_share_runtime
    assert boot_request.windows.primary_id == "window:workspace"
    assert boot_request.windows.continuity == :single_window
    assert Enum.map(boot_request.windows.sessions, & &1.id) == ["window:workspace"]
    assert boot_request.frame_request.primary_window_id == "window:workspace"
    assert boot_request.frame_request.presentation.backend == :sdl_renderer
    assert boot_request.frame_request.presentation.logical_units == :desktop_ui_layout
    assert boot_request.diagnostics.widget_count == 3
    assert boot_request.diagnostics.window_count == 1
    assert boot_request.lifecycle.state == :ready
    assert boot_request.lifecycle.callbacks.app_init == :ready
    assert boot_request.lifecycle.callbacks.app_event == :pending
  end

  test "canonical screens also converge onto the SDL3 boot request seam" do
    assert {:ok, boot_request} =
             App.boot_iur_screen(DesktopUi.Examples.canonical_foundational_screen(),
               platform_target: :linux
             )

    assert boot_request.foundation == :sdl3
    assert boot_request.runtime.source_kind == :canonical
    assert boot_request.runtime.direct_native_and_canonical_share_runtime
    assert boot_request.frame_request.presentation.render_target == :shared_sdl_runtime
    assert boot_request.windows.primary_id =~ "window:"
  end

  test "lifecycle diagnostics record failures and shutdown transitions deterministically" do
    lifecycle =
      Lifecycle.scaffold()
      |> Lifecycle.begin_boot(%{runtime_id: "desktop-ui:broken", screen_id: "broken"})
      |> Lifecycle.record_callback(:app_init, :ready)
      |> Lifecycle.fail(:callback_order_violation, %{callback: :app_quit})
      |> Lifecycle.begin_shutdown()

    diagnostics = Lifecycle.diagnostics(lifecycle)

    assert diagnostics.contract.foundation == :sdl3
    assert diagnostics.state == :shutting_down
    assert diagnostics.last_error.reason == :callback_order_violation
    assert Enum.any?(diagnostics.transitions, &(&1.reason == {:failed, :callback_order_violation}))
    assert List.last(diagnostics.transitions).reason == :shutdown_requested
  end

  test "lifecycle and handoff contracts expose the expected SDL3 seam" do
    assert App.lifecycle_contract().foundation == :sdl3
    assert App.handoff_contract().frame_backend == :sdl_renderer
    assert App.handoff_contract().logical_units_preserved
    assert DesktopUi.Sdl3.foundation().runtime_foundation == :sdl3
    assert :runtime_handoff in DesktopUi.Sdl3.adapter_scope()
    assert DesktopUi.Sdl3.validation_state() == :app_handoff_ready
  end
end
