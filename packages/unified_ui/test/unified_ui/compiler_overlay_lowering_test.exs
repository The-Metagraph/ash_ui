defmodule UnifiedUi.CompilerOverlayLoweringTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Tree
  alias UnifiedUi.Compiler

  defmodule OverlayWorkspace do
    use UnifiedUi.Dsl

    identity do
      id(:overlay_workspace)
      title("Overlay Workspace")
      authored_ref([:tests, :overlay_workspace])
    end

    composition do
      root(:overlay_workspace_root)
      mode(:screen)

      box :workspace_shell do
        text :workspace_copy do
          value("Workspace shell")
        end
      end

      box :settings_panel do
        text :settings_copy do
          value("Review escalation defaults")
        end
      end

      dialog :settings_dialog do
        title("Settings")
        content_ref(:settings_panel)
      end

      alert_dialog :danger_alert do
        title("Escalate incident")
        message("Paging the on-call owner will create a responder page.")
        confirm_intent(:confirm_escalation)
        dismiss_intent(:cancel_escalation)
        severity(:warning)
      end

      context_menu :workspace_menu do
        options(retry: "Retry", silence: "Silence")
        target_ref(:workspace_shell)
      end

      toast :save_toast do
        title("Saved")
        message("Runbook synced")
        severity(:success)
      end

      overlay :workspace_overlay do
        base_ref(:workspace_shell)
        layer_refs([:settings_dialog, :workspace_menu, :save_toast])
        background_fill(:scrim)
      end
    end
  end

  test "lowers overlay references into canonical content and overlay slots" do
    iur = Compiler.iur!(OverlayWorkspace)

    dialog = Tree.find_by_id(iur, :settings_dialog)
    alert_dialog = Tree.find_by_id(iur, :danger_alert)
    context_menu = Tree.find_by_id(iur, :workspace_menu)
    toast = Tree.find_by_id(iur, :save_toast)
    overlay = Tree.find_by_id(iur, :workspace_overlay)

    assert Enum.map(dialog.children, fn child ->
             {child.slot, child.element.id, child.element.kind}
           end) == [{:content, :settings_panel, :box}]

    assert Enum.map(alert_dialog.children, fn child ->
             {child.slot, child.element.kind}
           end) == [{:content, :text}]

    assert Enum.map(context_menu.children, fn child ->
             {child.slot, child.element.kind}
           end) == [{:menu, :menu}]

    assert Enum.map(toast.children, fn child ->
             {child.slot, child.element.id, child.element.kind}
           end) == [{:content, "save_toast_content", :box}]

    assert Enum.map(overlay.children, fn child ->
             {child.slot, child.element.id, child.element.kind}
           end) == [
             {:base, :workspace_shell, :box},
             {:overlay, :settings_dialog, :dialog},
             {:overlay, :workspace_menu, :context_menu},
             {:overlay, :save_toast, :toast}
           ]
  end
end
