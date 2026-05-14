defmodule DesktopUi.Platform.Linux do
  @moduledoc """
  Linux adapter seam for `desktop_ui`.
  """

  @behaviour DesktopUi.Platform.Adapter

  @impl true
  def summary do
    %{
      target: :linux,
      runtime_foundation: :sdl3,
      capabilities: capabilities(),
      callbacks: callbacks(),
      notifications: :desktop_portal,
      menus: :window_local_menu,
      integration: integration_profile(),
      allowed_variation: DesktopUi.Platform.Integration.allowed_variation(),
      shared_semantics: DesktopUi.Platform.Integration.shared_semantics()
    }
  end

  @impl true
  def integration_profile do
    %{
      windowing: %{chrome: :wm_managed_frame, controls: :window_manager},
      menus: %{surface: :window_local_menu, scope: :window},
      shortcuts: %{surface: :accelerators, scope: :window},
      notifications: %{surface: :desktop_portal, activation: :focus_window}
    }
  end

  @impl true
  def capabilities do
    [:windowing, :menus, :shortcuts, :notifications]
  end

  @impl true
  def callbacks do
    [:lifecycle, :focus, :window_management]
  end
end
