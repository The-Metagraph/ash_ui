defmodule DesktopUi.PlatformTest do
  use ExUnit.Case, async: true

  alias DesktopUi.Platform

  test "platform adapters stay bounded behind the shared registry" do
    assert Platform.targets() == [:windows, :macos, :linux]

    assert {:ok, %{target: :linux, adapter: DesktopUi.Platform.Linux}} =
             Platform.select(platform_target: :linux)

    assert Platform.adapter_summary(:windows).menus == :native_menu_bar
    assert Platform.adapter_summary(:macos).notifications == :user_notifications
    assert Platform.adapter_summary(:windows).integration.windowing.chrome == :native_frame
    assert Platform.adapter_summary(:linux).integration.notifications.surface == :desktop_portal

    assert Platform.diagnostics().integration.shared_semantics == [
             :widget_realization,
             :renderer_mapping,
             :transport_translation,
             :style_resolution
           ]

    assert Platform.diagnostics().integration.mismatches == []
  end

  test "invalid adapter registration and callback payloads fail deterministically" do
    assert {:error, {:invalid_platform_adapter, :linux}} =
             Platform.select(platform_target: :linux, adapter_registry: %{linux: DesktopUi})

    assert {:error, %{reason: :unsupported_platform_callback, callback: :printer_ready}} =
             Platform.validate_callback_payload(:printer_ready, %{})

    assert {:error, %{reason: :invalid_callback_payload, callback: :lifecycle}} =
             Platform.validate_callback_payload(:lifecycle, :not_a_map)
  end

  test "integration diagnostics keep target variation bounded under shared semantics" do
    windows = DesktopUi.Platform.Integration.target_profile(:windows)
    macos = DesktopUi.Platform.Integration.target_profile(:macos)
    linux = DesktopUi.Platform.Integration.target_profile(:linux)

    assert windows.allowed_variation == [
             :window_controls,
             :menu_shape,
             :shortcut_scope,
             :notification_style
           ]

    assert macos.integration.menus.scope == :application
    assert linux.integration.windowing.controls == :window_manager
    assert windows.continuity.shared_runtime
    assert macos.continuity.shared_renderer
    assert linux.continuity.bounded_variation_only
  end
end
