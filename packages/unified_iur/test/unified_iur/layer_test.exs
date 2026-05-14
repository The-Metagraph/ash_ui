defmodule UnifiedIUR.LayerTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Container
  alias UnifiedIUR.Element
  alias UnifiedIUR.Layer
  alias UnifiedIUR.Widgets.Foundational

  test "exposes canonical layering kinds" do
    assert [:overlay, :dialog, :toast, :alert_dialog, :context_menu] == Layer.kinds()
  end

  test "builds overlays with base content, positioned layered children, and fill metadata" do
    base =
      Container.box([{:content, Foundational.text("Base", id: "base-text")}], id: "base-shell")

    dialog_content =
      Container.content(
        [
          {:content, Foundational.label("Dialog", id: "dialog-title")},
          {:content, Foundational.text("Body", id: "dialog-body")}
        ],
        id: "dialog-content"
      )

    overlay =
      Layer.overlay(
        base,
        [
          {:overlay,
           Layer.dialog(dialog_content, id: "dialog-layer", title: "Settings", size: :lg)}
        ],
        id: "overlay-root",
        mode: :stacked,
        background_fill: :scrim,
        dismissible?: true
      )

    assert %Element{
             kind: :overlay,
             children: [base_child, overlay_child],
             attributes: %{
               overlay: %{mode: :stacked, background_fill: :scrim, dismissible?: true}
             }
           } = overlay

    assert base_child.slot == :base
    assert base_child.element.id == "base-shell"
    assert overlay_child.slot == :overlay
    assert overlay_child.element.id == "dialog-layer"
  end

  test "builds dialog, toast, alert dialog, and context menu layer constructs" do
    dialog =
      Layer.dialog(
        Container.content([{:content, Foundational.text("Dialog body", id: "dialog-copy")}],
          id: "dialog-content"
        ),
        id: "dialog",
        title: "Settings"
      )

    toast =
      Layer.toast(
        Foundational.text("Saved", id: "toast-copy"),
        id: "save-toast",
        severity: :success,
        placement: :bottom_end
      )

    alert =
      Layer.alert_dialog(
        Container.content([{:content, Foundational.text("Delete item?", id: "alert-copy")}],
          id: "alert-content"
        ),
        id: "delete-alert",
        title: "Confirm delete",
        severity: :error
      )

    context_menu =
      Layer.context_menu(
        [
          [id: :copy, label: "Copy", active?: true],
          [id: :delete, label: "Delete"]
        ],
        id: "context-actions",
        anchor: %{target_id: "row-1", x: 14, y: 8},
        placement: :bottom_start
      )

    assert %Element{
             kind: :dialog,
             attributes: %{
               dialog: %{
                 title: "Settings",
                 modal?: true,
                 dismissible?: true,
                 size: :md,
                 background_fill: :scrim,
                 focus_scope: :dialog
               }
             }
           } = dialog

    assert %Element{
             kind: :toast,
             attributes: %{
               toast: %{
                 placement: :bottom_end,
                 duration_ms: 5000,
                 severity: :success,
                 transient?: true
               }
             }
           } = toast

    assert %Element{
             kind: :alert_dialog,
             attributes: %{
               alert_dialog: %{
                 title: "Confirm delete",
                 severity: :error,
                 requires_confirmation?: true,
                 background_fill: :scrim,
                 focus_scope: :alert_dialog
               }
             }
           } = alert

    assert %Element{
             kind: :context_menu,
             children: [%{slot: :menu, element: %Element{kind: :menu}}],
             attributes: %{
               context_menu: %{
                 anchor: %{target_id: "row-1", x: 14, y: 8},
                 placement: :bottom_start,
                 dismissible?: true,
                 background_fill: :none
               }
             }
           } = context_menu
  end
end
