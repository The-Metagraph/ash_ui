defmodule UnifiedIUR.Widgets.NavigationTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Element
  alias UnifiedIUR.Widgets.Navigation

  test "builds menu and tab navigation structures with active state metadata" do
    menu =
      Navigation.menu(
        [
          [id: :home, label: "Home", value: :home, active?: true],
          [id: :settings, label: "Settings", value: :settings]
        ],
        id: "main-menu",
        active_item: :home
      )

    tabs =
      Navigation.tabs(
        [
          [id: :overview, label: "Overview", value: :overview, active?: true],
          [id: :details, label: "Details", value: :details]
        ],
        id: "detail-tabs",
        active_item: :overview
      )

    assert %Element{
             kind: :menu,
             attributes: %{
               navigation: %{
                 orientation: :vertical,
                 active_item: :home,
                 items: [
                   %{id: :home, label: "Home", value: :home, active?: true},
                   %{id: :settings, label: "Settings", value: :settings}
                 ]
               }
             }
           } = menu

    assert %Element{
             kind: :tabs,
             attributes: %{
               navigation: %{
                 orientation: :horizontal,
                 active_item: :overview,
                 items: [
                   %{id: :overview, label: "Overview", value: :overview, active?: true},
                   %{id: :details, label: "Details", value: :details}
                 ]
               }
             }
           } = tabs
  end
end
