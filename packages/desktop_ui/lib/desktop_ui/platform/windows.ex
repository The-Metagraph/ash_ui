defmodule DesktopUi.Platform.Windows do
  @moduledoc """
  Windows adapter seam for `desktop_ui`.
  """

  @behaviour DesktopUi.Platform.Adapter

  @impl true
  def summary do
    %{
      target: :windows,
      runtime_foundation: :sdl3,
      capabilities: capabilities(),
      callbacks: callbacks(),
      notifications: :system_toast,
      menus: :native_menu_bar,
      integration: integration_profile(),
      allowed_variation: DesktopUi.Platform.Integration.allowed_variation(),
      shared_semantics: DesktopUi.Platform.Integration.shared_semantics()
    }
  end

  @impl true
  def integration_profile do
    %{
      windowing: %{chrome: :native_frame, controls: :win32_caption_buttons},
      menus: %{surface: :native_menu_bar, scope: :window},
      shortcuts: %{surface: :accelerators, scope: :window_and_application},
      notifications: %{surface: :system_toast, activation: :focus_window}
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
