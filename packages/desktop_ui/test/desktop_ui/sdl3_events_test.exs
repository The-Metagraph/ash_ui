defmodule DesktopUi.Sdl3EventsTest do
  use ExUnit.Case, async: true

  alias DesktopUi.Runtime.Error
  alias DesktopUi.Sdl3.{Events, Images, Text}

  test "SDL3 events normalize keyboard, wheel, and focus payloads into runtime-safe input maps" do
    assert {:ok, keyboard} =
             Events.normalize(
               type: :keyboard_key_down,
               key: "enter",
               text: "\n",
               widget_id: "query-input",
               window_id: "window:workspace",
               runtime_id: "desktop-ui:workspace",
               screen: "workspace",
               platform_target: :linux
             )

    assert keyboard.input_family == :keyboard
    assert keyboard.family == :change
    assert keyboard.runtime_event == "keyboard:key_down"

    assert {:ok, wheel} =
             Events.normalize(
               type: :wheel_scrolled,
               widget_id: "services-viewport",
               window_id: "window:workspace",
               delta_y: -3,
               pointer: %{x: 12, y: 48}
             )

    assert wheel.input_family == :pointer
    assert wheel.pointer_action == :scroll
    assert wheel.payload.wheel.y == -3

    assert {:ok, focus} =
             Events.normalize(
               type: :focus_changed,
               focus_target: "save-button",
               window_id: "window:workspace"
             )

    assert focus.input_family == :focus
    assert focus.widget_id == "save-button"
    assert Events.contract().foundation == :sdl3
    assert :wheel_scrolled in Events.event_types()
  end

  test "SDL3 events dispatch through the shared runtime and reject invalid routing or focus transitions" do
    assert {:ok, state} =
             DesktopUi.Runtime.mount_native_screen(
               DesktopUi.Examples.native_foundational_screen(),
               platform_target: :linux
             )

    assert {:ok, next_state, route_result} =
             Events.dispatch(state,
               type: :focus_changed,
               focus_target: "workspace-tabs",
               window_id: state.windows.primary,
               runtime_id: state.runtime_id,
               screen: state.screen_id,
               platform_target: state.platform_target
             )

    assert route_result.route == :local_runtime
    assert route_result.normalized_event.input_family == :focus
    assert next_state.focus.current == "workspace-tabs"

    assert {:error, %Error{} = invalid_window_error} =
             Events.dispatch(state,
               type: :window_activated,
               window_id: "window:missing",
               runtime_id: state.runtime_id,
               screen: state.screen_id
             )

    assert invalid_window_error.reason == :mismatched_window_local_event_routing

    assert {:error, %Error{} = invalid_focus_error} =
             Events.dispatch(state,
               type: :focus_changed,
               focus_target: "missing-focus-target",
               window_id: state.windows.primary
             )

    assert invalid_focus_error.reason == :invalid_focus_transition
  end

  test "SDL3 text and image seams prepare companion-library resources deterministically" do
    assert {:ok, text_surface} = Text.prepare("Workspace", size: 16, font: "ui-sans")
    assert text_surface.backend == :sdl_ttf_equivalent
    assert text_surface.measurement.units == :logical
    assert text_surface.validation_state == :text_resource_ready

    assert {:ok, image_surface} = Images.prepare("assets/logo.png", size: {64, 64})
    assert image_surface.backend == :sdl_image_equivalent
    assert image_surface.validation_state == :image_resource_ready

    assert {:ok, pixel_surface} = Images.from_pixels(<<0, 1, 2, 3>>, width: 1, height: 1)
    assert pixel_surface.backend == :raw_pixels
    assert pixel_surface.pixel_count == 4
    assert Images.contract().future_platform_image_allowed
    assert Text.contract().future_platform_text_allowed
  end
end
