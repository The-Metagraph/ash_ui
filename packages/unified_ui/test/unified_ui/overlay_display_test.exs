defmodule UnifiedUi.OverlayDisplayTest do
  use ExUnit.Case, async: true

  alias Spark.Dsl.Extension

  defmodule OverlayWorkspace do
    use UnifiedUi.Dsl

    identity do
      id(:overlay_workspace)
      authored_ref([:examples, :overlay_workspace])
    end

    composition do
      root(:overlay_workspace_root)
      mode(:screen)

      row :workspace_shell do
        button :open_settings do
          label("Open settings")
        end

        button :open_context do
          label("Open menu")
        end
      end

      box :settings_panel do
        text :settings_title do
          value("Settings")
        end
      end

      dialog :settings_dialog do
        title("Settings")
        content_ref(:settings_panel)
        trigger_ref(:open_settings)
        visible?(true)
      end

      alert_dialog :danger_alert do
        title("Archive workspace")
        message("Archiving this workspace cannot be undone.")
        confirm_intent(:archive_workspace)
        dismiss_intent(:cancel_archive)
        severity(:warning)
      end

      context_menu :workspace_menu do
        options(edit: "Edit", archive: "Archive")
        target_ref(:workspace_shell)
        trigger_ref(:open_context)
      end

      toast :save_toast do
        title("Saved")
        message("Workspace updated")
        placement(:bottom_end)
        severity(:success)
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

  test "registers overlay and display kinds for package inspection" do
    assert UnifiedUi.Layer.kinds() == [
             :context_menu,
             :dialog,
             :alert_dialog,
             :toast,
             :overlay,
             :absolute
           ]

    assert UnifiedUi.Display.kinds() == [:scroll_bar, :split_pane, :viewport, :scroll_region]
  end

  test "stores overlay-driven and split-pane nodes in authored composition" do
    nodes = Extension.get_entities(OverlayWorkspace, [:composition])

    assert Enum.map(nodes, &{&1.id, &1.family, &1.kind}) == [
             {:workspace_shell, :layout, :row},
             {:settings_panel, :layout, :box},
             {:settings_dialog, :overlay, :dialog},
             {:danger_alert, :overlay, :alert_dialog},
             {:workspace_menu, :overlay, :context_menu},
             {:save_toast, :overlay, :toast},
             {:workspace_split, :display, :split_pane},
             {:workspace_scroll, :display, :scroll_bar}
           ]
  end

  test "summarizes overlay-driven authored flows without renderer runtime dependencies" do
    assert UnifiedUi.Info.composition_summary(OverlayWorkspace) == [
             %{
               id: :workspace_shell,
               family: :layout,
               kind: :row,
               children: [
                 %{
                   id: :open_settings,
                   family: :foundational,
                   kind: :button,
                   label: "Open settings"
                 },
                 %{id: :open_context, family: :foundational, kind: :button, label: "Open menu"}
               ]
             },
             %{
               id: :settings_panel,
               family: :layout,
               kind: :box,
               children: [
                 %{
                   id: :settings_title,
                   family: :foundational,
                   kind: :text,
                   role: :text,
                   value: "Settings"
                 }
               ]
             },
             %{
               id: :settings_dialog,
               family: :overlay,
               kind: :dialog,
               title: "Settings",
               content_ref: :settings_panel,
               trigger_ref: :open_settings
             },
             %{
               id: :danger_alert,
               family: :overlay,
               kind: :alert_dialog,
               title: "Archive workspace",
               message: "Archiving this workspace cannot be undone.",
               severity: :warning
             },
             %{
               id: :workspace_menu,
               family: :overlay,
               kind: :context_menu,
               target_ref: :workspace_shell,
               trigger_ref: :open_context,
               placement: :bottom_start
             },
             %{
               id: :save_toast,
               family: :overlay,
               kind: :toast,
               title: "Saved",
               message: "Workspace updated",
               severity: :success,
               placement: :bottom_end
             },
             %{
               id: :workspace_split,
               family: :display,
               kind: :split_pane,
               primary_ref: :workspace_shell,
               secondary_ref: :settings_panel,
               ratio: 0.35
             },
             %{
               id: :workspace_scroll,
               family: :display,
               kind: :scroll_bar,
               target_ref: :workspace_shell,
               position: 4,
               viewport_size: 24,
               content_size: 120
             }
           ]
  end

  test "rejects invalid overlay references and split-pane misuse at compile time" do
    assert_compile_dsl_error(
      """
      identity do
        id(:broken_dialog)
      end

      composition do
        root(:broken_dialog_root)

        dialog :broken do
          title("Broken")
          content_ref(:missing_panel)
        end
      end
      """,
      "references missing content_ref"
    )

    assert_compile_dsl_error(
      """
      identity do
        id(:broken_split)
      end

      composition do
        root(:broken_split_root)

        box :panel do
          text :copy do
            value("Panel")
          end
        end

        split_pane :broken do
          primary_ref(:panel)
          secondary_ref(:panel)
        end
      end
      """,
      "must reference two distinct authored nodes"
    )
  end

  defp compile_module(body) do
    module_name = "Generated#{System.unique_integer([:positive])}"

    Code.compile_string("""
    defmodule UnifiedUi.OverlayDisplayTest.#{module_name} do
      use UnifiedUi.Dsl

      #{body}
    end
    """)
  end

  defp assert_compile_dsl_error(body, expected_message) do
    {pid, ref} = spawn_monitor(fn -> compile_module(body) end)

    receive do
      {:DOWN, ^ref, :process, ^pid, :normal} ->
        flunk("expected authored module compilation to fail, but it succeeded")

      {:DOWN, ^ref, :process, ^pid, reason} ->
        assert Exception.format_exit(reason) =~ expected_message
    end
  end
end
