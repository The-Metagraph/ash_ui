defmodule DesktopUi.TransportTest do
  use ExUnit.Case, async: true

  alias Jido.Signal
  alias DesktopUi.Transport
  alias UnifiedIUR.Interaction

  test "native desktop input normalizes before canonical boundary translation" do
    assert {:ok, normalized} =
             Transport.normalize_native_event(
               platform_target: :macos,
               input_family: :shortcut,
               shortcut: "cmd-r",
               intent: :reload_workspace,
               widget_id: "ops-palette",
               runtime_id: "desktop-ui:ops",
               screen: "operations"
             )

    assert normalized.input_family == :shortcut
    assert normalized.family == :command
    assert normalized.boundary == :boundary
    assert normalized.normalized_input.shortcut == "cmd-r"
    assert normalized.platform_target == :macos

    assert {:ok, translation} =
             Transport.from_native_event(
               platform_target: :macos,
               input_family: :shortcut,
               shortcut: "cmd-r",
               intent: :reload_workspace,
               widget_id: "ops-palette",
               runtime_id: "desktop-ui:ops",
               screen: "operations"
             )

    assert translation.family == :command
    assert translation.boundary == :boundary
    assert match?(%Signal{}, translation.signal)
    assert translation.cloud_event.type == "desktop_ui.command.reload_workspace"
    assert translation.cloud_event.extensions.desktop_ui_input_family == :shortcut
  end

  test "local native focus handling can remain inside the runtime without a signal" do
    assert {:ok, translation} =
             Transport.from_native_event(
               platform_target: :linux,
               input_family: :focus,
               focus_target: "services-table",
               intent: :focus_services_table,
               widget_id: "services-table",
               boundary: :local
             )

    assert translation.family == :focus
    assert translation.boundary == :local
    assert translation.signal == nil
    assert translation.local_handling == :focus_handoff
  end

  test "canonical interactions translate into canonical boundary signals" do
    interaction = Interaction.command(intent: :run_command, command: :reload)

    assert {:ok, translation} =
             Transport.from_interaction(
               interaction,
               platform_target: :windows,
               widget_id: "ops-palette",
               runtime_id: "desktop-ui:ops",
               screen: "operations",
               payload: %{query: "re"}
             )

    assert translation.family == :command
    assert translation.source_kind == :canonical
    assert translation.platform_target == :windows
    assert match?(%Signal{}, translation.signal)
    assert translation.payload == %{command: :reload, query: "re"}
  end

  test "boundary signals decode back into shared desktop transport translations" do
    assert {:ok, outbound} =
             Transport.from_native_event(
               platform_target: :linux,
               input_family: :pointer,
               pointer_action: :select,
               widget_id: "services-table",
               runtime_id: "desktop-ui:ops",
               screen: "operations"
             )

    assert {:ok, inbound} = Transport.from_boundary_signal(outbound.signal)

    assert inbound.boundary == :boundary
    assert inbound.family == :selection
    assert inbound.screen == "operations"
    assert inbound.widget_id == outbound.signal.subject
  end

  test "invalid native payloads and leaked platform details fail deterministically" do
    assert {:error, %DesktopUi.Transport.Error{reason: :invalid_payload_mapping}} =
             Transport.from_native_event(
               platform_target: :linux,
               input_family: :menu,
               menu_item: :reload_workspace,
               payload: "not-a-map"
             )

    assert {:error, %DesktopUi.Transport.Error{reason: :leaked_platform_detail}} =
             Transport.normalize_native_event(
               platform_target: :linux,
               input_family: :keyboard,
               key: "enter",
               sdl_event: %{scancode: 40}
             )
  end

  test "invalid canonical navigation fields fail at the desktop boundary" do
    assert {:error,
            %DesktopUi.Transport.Error{reason: :host_route_syntax, details: %{keys: [:stack_id]}}} =
             Transport.from_native_event(
               platform_target: :linux,
               input_family: :pointer,
               pointer_action: :click,
               widget_id: "confirm-settings-button",
               runtime_id: "desktop-ui:ops",
               screen: "operations",
               target: %{
                 navigation: %{
                   action: :open_modal,
                   modal: :settings_confirm_dialog,
                   modal_stack: %{
                     operation: :push,
                     target: :symbolic_modal,
                     stack_effect: :push_modal,
                     stack_id: "desktop-runtime-stack"
                   }
                 }
               }
             )
  end

  test "transport diagnostics validate no-leakage guarantees and boundary signals" do
    assert :ok ==
             Transport.validate_native_event(
               platform_target: :linux,
               input_family: :focus,
               boundary: :local,
               focus_target: "services-table",
               widget_id: "services-table"
             )

    assert {:ok, translation} =
             Transport.from_native_event(
               platform_target: :windows,
               input_family: :shortcut,
               shortcut: "ctrl-r",
               runtime_id: "desktop-ui:ops",
               widget_id: "ops-palette",
               screen: "operations"
             )

    assert :ok == Transport.validate_translation(translation)
    assert :ok == Transport.validate_boundary_signal(translation.signal)
    assert :transport_diagnostics in Transport.integration_points()

    assert Transport.diagnostics().mapping_summary.platform_targets ==
             DesktopUi.Platform.targets()
  end
end
