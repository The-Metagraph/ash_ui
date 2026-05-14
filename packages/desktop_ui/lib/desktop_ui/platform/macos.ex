defmodule DesktopUi.Platform.MacOS do
  @moduledoc """
  macOS adapter seam for `desktop_ui`.
  """

  @behaviour DesktopUi.Platform.Adapter

  @impl true
  def summary do
    %{
      target: :macos,
      runtime_foundation: :sdl3,
      capabilities: capabilities(),
      callbacks: callbacks(),
      notifications: :user_notifications,
      menus: :application_menu,
      integration: integration_profile(),
      allowed_variation: DesktopUi.Platform.Integration.allowed_variation(),
      shared_semantics: DesktopUi.Platform.Integration.shared_semantics()
    }
  end

  @impl true
  def integration_profile do
    %{
      windowing: %{chrome: :native_titlebar, controls: :traffic_lights},
      menus: %{surface: :application_menu, scope: :application},
      shortcuts: %{surface: :native_shortcuts, scope: :application_first},
      notifications: %{surface: :user_notifications, activation: :reopen_window}
    }
  end

  @impl true
  def capabilities do
    [:windowing, :menus, :shortcuts, :notifications, :file_open]
  end

  @impl true
  def callbacks do
    [:lifecycle, :focus, :file_open, :window_management]
  end
end
