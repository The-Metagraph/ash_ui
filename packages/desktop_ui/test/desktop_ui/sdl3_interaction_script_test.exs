defmodule DesktopUi.Sdl3InteractionScriptTest do
  use ExUnit.Case, async: true

  alias DesktopUi.Sdl3.InteractionScript

  test "interaction script encodes deterministic events for the compiled visible runner" do
    assert {:ok, script} =
             InteractionScript.encode([
               %{
                 type: :focus_changed,
                 window_id: "window:operations",
                 focus_target: "services-table"
               },
               %{
                 type: :keyboard_key_down,
                 window_id: "window:operations",
                 key: "Tab",
                 modifiers: [:shift]
               },
               %{
                 type: :wheel_scrolled,
                 window_id: "window:operations",
                 widget_id: "services-table",
                 pointer: %{x: 48, y: 120},
                 delta_y: -1
               }
             ])

    assert script =~ "DESKTOP_UI_SDL3_INTERACTION\tversion=1"

    assert script =~
             "EVENT\ttype=focus_changed\twindow_id=window%3Aoperations\tfocus_target=services-table"

    assert script =~
             "EVENT\ttype=keyboard_key_down\twindow_id=window%3Aoperations\tkey=Tab\tmodifiers=shift"

    assert script =~
             "EVENT\ttype=wheel_scrolled\twindow_id=window%3Aoperations\twidget_id=services-table\tx=48\ty=120\tdelta_y=-1"
  end
end
