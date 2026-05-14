defmodule LiveUi.OverlayWidgetsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Component
  alias LiveUi.Widget.Identity

  @moduledoc """
  Regression tests for overlay widgets to verify they preserve
  identity, styling, slots, and event semantics through the widget
  component architecture.
  """

  describe "overlay_surface widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.OverlaySurface)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.OverlaySurface.Component
      assert metadata.family == :overlay
      assert metadata.name == :overlay_surface
    end

    test "overlay_surface component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.OverlaySurface.component/1, %{
          id: "test-overlay",
          base: [%{__slot__: :base, inner_block: fn _, _ -> "Base content" end}]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="overlay_surface")
      assert html =~ "Base content"
    end

    test "overlay_surface supports overlay slots" do
      html =
        render_component(&LiveUi.Widgets.OverlaySurface.component/1, %{
          id: "overlay-slot-test",
          base: [%{__slot__: :base, inner_block: fn _, _ -> "Base" end}],
          overlay: [
            %{__slot__: :overlay, inner_block: fn _, _ -> "Overlay content" end}
          ]
        })

      assert html =~ "Base"
      assert html =~ "Overlay content"
      assert html =~ ~s(data-live-ui-overlay-slot="overlay")
    end

    test "overlay_surface supports dismissible mode" do
      html =
        render_component(&LiveUi.Widgets.OverlaySurface.component/1, %{
          id: "dismissible-overlay",
          base: [%{__slot__: :base, inner_block: fn _, _ -> "Content" end}],
          dismissible: true
        })

      assert html =~ ~s(data-live-ui-dismissible)
    end
  end

  describe "dialog widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.Dialog)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.Dialog.Component
      assert metadata.family == :overlay
      assert metadata.name == :dialog
    end

    test "dialog component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.Dialog.component/1, %{
          id: "test-dialog",
          title: "Test Dialog",
          inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "Dialog content" end}]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="dialog")
      assert html =~ "Test Dialog"
      assert html =~ "Dialog content"
    end

    test "dialog supports open state" do
      html =
        render_component(&LiveUi.Widgets.Dialog.component/1, %{
          id: "open-dialog",
          inner_block: [],
          open: true
        })

      assert html =~ ~s(data-live-ui-open)
    end

    test "dialog supports modal mode" do
      html =
        render_component(&LiveUi.Widgets.Dialog.component/1, %{
          id: "modal-dialog",
          inner_block: [],
          modal: true
        })

      assert html =~ ~s(data-live-ui-modal)
    end

    test "dialog supports size variants" do
      html =
        render_component(&LiveUi.Widgets.Dialog.component/1, %{
          id: "sized-dialog",
          inner_block: [],
          size: "lg"
        })

      assert html =~ ~s(data-live-ui-size="lg")
    end

    test "dialog supports actions slot" do
      html =
        render_component(&LiveUi.Widgets.Dialog.component/1, %{
          id: "actions-dialog",
          inner_block: [],
          actions: [%{__slot__: :actions, inner_block: fn _, _ -> "Action buttons" end}]
        })

      assert html =~ "Action buttons"
      assert html =~ ~s(data-live-ui-dialog-slot="actions")
    end

    test "dialog supports dismissible mode" do
      html =
        render_component(&LiveUi.Widgets.Dialog.component/1, %{
          id: "dismissible-dialog",
          inner_block: [],
          dismissible: true
        })

      assert html =~ ~s(data-live-ui-dismissible)
    end
  end

  describe "alert_dialog widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.AlertDialog)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.AlertDialog.Component
      assert metadata.family == :overlay
      assert metadata.name == :alert_dialog
    end

    test "alert_dialog component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.AlertDialog.component/1, %{
          id: "test-alert",
          title: "Confirm Action",
          inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "Are you sure?" end}]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="alert_dialog")
      assert html =~ "Confirm Action"
      assert html =~ "Are you sure?"
    end

    test "alert_dialog supports severity levels" do
      html =
        render_component(&LiveUi.Widgets.AlertDialog.component/1, %{
          id: "critical-alert",
          inner_block: [],
          severity: "critical"
        })

      assert html =~ ~s(data-live-ui-severity="critical")
    end

    test "alert_dialog supports confirmation requirement" do
      html =
        render_component(&LiveUi.Widgets.AlertDialog.component/1, %{
          id: "confirmation-alert",
          inner_block: [],
          requires_confirmation: true
        })

      assert html =~ ~s(data-live-ui-requires-confirmation)
    end
  end

  describe "context_menu widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.ContextMenu)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.ContextMenu.Component
      assert metadata.family == :overlay
      assert metadata.name == :context_menu
    end

    test "context_menu component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.ContextMenu.component/1, %{
          id: "test-menu",
          items: [
            %{id: "item-1", label: "Option 1"},
            %{id: "item-2", label: "Option 2"}
          ]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="context_menu")
      assert html =~ "Option 1"
      assert html =~ "Option 2"
    end

    test "context_menu supports open state" do
      html =
        render_component(&LiveUi.Widgets.ContextMenu.component/1, %{
          id: "open-menu",
          items: [],
          open: true
        })

      assert html =~ ~s(data-live-ui-open)
    end

    test "context_menu supports placement options" do
      html =
        render_component(&LiveUi.Widgets.ContextMenu.component/1, %{
          id: "placed-menu",
          items: [],
          placement: "top-end"
        })

      assert html =~ ~s(data-live-ui-placement="top-end")
    end

    test "context_menu supports anchor positioning" do
      html =
        render_component(&LiveUi.Widgets.ContextMenu.component/1, %{
          id: "anchored-menu",
          items: [],
          anchor: %{x: 100, y: 200}
        })

      assert html =~ ~s(data-live-ui-anchor-x="100")
      assert html =~ ~s(data-live-ui-anchor-y="200")
    end

    test "context_menu supports active item tracking" do
      html =
        render_component(&LiveUi.Widgets.ContextMenu.component/1, %{
          id: "active-menu",
          items: [
            %{id: "item-1", label: "Active"},
            %{id: "item-2", label: "Inactive"}
          ],
          active_item: "item-1"
        })

      assert html =~ ~s(data-active)
    end
  end

  describe "toast widget" do
    test "has mountable component boundary" do
      metadata = Component.metadata(LiveUi.Widgets.Toast)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.Toast.Component
      assert metadata.family == :overlay
      assert metadata.name == :toast
    end

    test "toast component renders with widget boundary attributes" do
      html =
        render_component(&LiveUi.Widgets.Toast.component/1, %{
          id: "test-toast",
          inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "Toast message" end}]
        })

      assert html =~ ~s(data-live-ui-widget-boundary="toast")
      assert html =~ "Toast message"
    end

    test "toast supports open state" do
      html =
        render_component(&LiveUi.Widgets.Toast.component/1, %{
          id: "open-toast",
          inner_block: [],
          open: true
        })

      assert html =~ ~s(data-live-ui-open)
    end

    test "toast supports placement options" do
      html =
        render_component(&LiveUi.Widgets.Toast.component/1, %{
          id: "placed-toast",
          inner_block: [],
          placement: "bottom-start"
        })

      assert html =~ ~s(data-live-ui-placement="bottom-start")
    end

    test "toast supports duration configuration" do
      html =
        render_component(&LiveUi.Widgets.Toast.component/1, %{
          id: "timed-toast",
          inner_block: [],
          duration_ms: 3000
        })

      assert html =~ ~s(data-live-ui-duration-ms="3000")
    end

    test "toast supports severity levels" do
      html =
        render_component(&LiveUi.Widgets.Toast.component/1, %{
          id: "error-toast",
          inner_block: [],
          severity: "error"
        })

      assert html =~ ~s(data-live-ui-severity="error")
    end
  end

  describe "widget identity preservation" do
    test "widget identity is stable across renders for dialog" do
      identity1 =
        Identity.new(
          Component.metadata(LiveUi.Widgets.Dialog),
          %{id: "stable-dialog"}
        )

      identity2 =
        Identity.new(
          Component.metadata(LiveUi.Widgets.Dialog),
          %{id: "stable-dialog"}
        )

      assert identity1.id == identity2.id
      assert Identity.key(identity1) == Identity.key(identity2)
      assert Identity.key(identity1) == "native:overlay:dialog:stable-dialog:root"
    end

    test "widget identity includes mode in key for toast" do
      native_identity =
        Identity.new(
          Component.metadata(LiveUi.Widgets.Toast),
          %{id: "mode-toast"},
          mode: :native
        )

      canonical_identity =
        Identity.new(
          Component.metadata(LiveUi.Widgets.Toast),
          %{id: "mode-toast"},
          mode: :canonical
        )

      assert Identity.key(native_identity) == "native:overlay:toast:mode-toast:root"
      assert Identity.key(canonical_identity) == "canonical:overlay:toast:mode-toast:root"
    end
  end

  describe "event semantics preservation" do
    test "context_menu has click events in metadata" do
      metadata = Component.metadata(LiveUi.Widgets.ContextMenu)

      assert :click in metadata.events
    end
  end

  describe "bounded local state support" do
    test "overlay widgets support local_state_keys for bounded state" do
      dialog_metadata = Component.metadata(LiveUi.Widgets.Dialog)
      context_menu_metadata = Component.metadata(LiveUi.Widgets.ContextMenu)
      toast_metadata = Component.metadata(LiveUi.Widgets.Toast)

      # Overlay widgets can have local_state_keys for bounded UI state
      # like open, expanded, placement, etc.
      assert is_list(dialog_metadata.local_state_keys)
      assert is_list(context_menu_metadata.local_state_keys)
      assert is_list(toast_metadata.local_state_keys)
    end
  end

  describe "overlay lifecycle behavior" do
    test "overlay_surface supports mode attribute" do
      html =
        render_component(&LiveUi.Widgets.OverlaySurface.component/1, %{
          id: "mode-overlay",
          base: [%{__slot__: :base, inner_block: fn _, _ -> "Content" end}],
          mode: "stacked"
        })

      assert html =~ ~s(data-live-ui-mode)
    end

    test "overlay_surface supports background fill options" do
      html =
        render_component(&LiveUi.Widgets.OverlaySurface.component/1, %{
          id: "scrim-overlay",
          base: [%{__slot__: :base, inner_block: fn _, _ -> "Content" end}],
          background_fill: "scrim"
        })

      assert html =~ ~s(data-live-ui-background-fill="scrim")
    end
  end
end
