defmodule UnifiedUi.Examples.OverlayWorkspace do
  @moduledoc """
  Reference workflow for advanced overlay, contextual, and split-pane authoring.
  """

  use UnifiedUi.Dsl

  identity do
    id(:overlay_workspace_example)
    title("Overlay Workspace Example")
    authored_ref([:examples, :overlay_workspace_example])
    tags([:example, :overlay])
  end

  composition do
    root(:overlay_workspace_example_root)
    mode(:screen)

    row :workspace_shell do
      gap(:md)

      button :open_settings do
        label("Open settings")
        action_intent(:open_settings)
      end

      button :open_context do
        label("Open menu")
        action_intent(:open_context_menu)
      end
    end

    box :settings_panel do
      summary("Settings panel")

      text :settings_heading do
        value("Workspace settings")
      end

      text :settings_copy do
        value("Advanced workspace options")
      end
    end

    dialog :settings_dialog do
      title("Settings")
      content_ref(:settings_panel)
      trigger_ref(:open_settings)
      visible?(true)
      confirm_intent(:save_settings)
      dismiss_intent(:close_settings)
    end

    context_menu :workspace_menu do
      options(edit: "Edit", archive: "Archive")
      target_ref(:workspace_shell)
      trigger_ref(:open_context)
      visible?(true)
    end

    toast :save_toast do
      title("Saved")
      message("Workspace settings updated")
      severity(:success)
      visible?(true)
    end

    split_pane :workspace_split do
      primary_ref(:workspace_shell)
      secondary_ref(:settings_panel)
      ratio(0.35)
    end

    scroll_bar :workspace_scroll do
      target_ref(:workspace_shell)
      position(4)
      viewport_size(24)
      content_size(120)
    end
  end
end
