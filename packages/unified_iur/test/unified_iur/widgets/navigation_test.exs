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

  describe "context_selector/1" do
    test "builds a grouped context selector with canonical navigation attributes" do
      element =
        Navigation.context_selector(
          id: "context-selector",
          selector_id: "workspace-context",
          groups: [
            %{
              id: :workspace,
              label: "Workspace",
              items: [
                %{value: :all, label: "All workspaces", selected?: true},
                %{value: :active, label: "Active workspace", disabled?: true}
              ]
            }
          ],
          selected_values: [:all],
          max_selections: 1,
          selection_intent: :select_context
        )

      assert %Element{type: :widget, kind: :context_selector} = element
      assert element.id == "context-selector"

      assert element.attributes.context_selector == %{
               selector_id: "workspace-context",
               groups: [
                 %{
                   id: "workspace",
                   label: "Workspace",
                   items: [
                     %{id: :all, value: :all, label: "All workspaces", selected?: true},
                     %{
                       id: :active,
                       value: :active,
                       label: "Active workspace",
                       disabled?: true
                     }
                   ]
                 }
               ],
               placeholder: "Select context...",
               selected_values: [:all],
               max_selections: 1,
               multiple?: false,
               label_prefix: "context:",
               open?: false,
               disabled?: false,
               selection_intent: :select_context
             }
    end

    test "supports multi-select contexts" do
      element =
        Navigation.context_selector(
          selector_id: :multi_context,
          groups: [],
          selected_values: [:a, :b],
          max_selections: :unlimited
        )

      assert element.id == "multi_context"
      assert element.attributes.context_selector.max_selections == :unlimited
      assert element.attributes.context_selector.multiple?
    end

    test "raises for missing identity, malformed groups, and invalid max selections" do
      assert_raise ArgumentError, ~r/selector_id/, fn ->
        Navigation.context_selector(groups: [])
      end

      assert_raise ArgumentError, ~r/group_label/, fn ->
        Navigation.context_selector(
          selector_id: "context",
          groups: [%{id: :workspace, items: []}]
        )
      end

      assert_raise ArgumentError, ~r/value/, fn ->
        Navigation.context_selector(
          selector_id: "context",
          groups: [%{id: :workspace, label: "Workspace", items: [%{label: "All"}]}]
        )
      end

      assert_raise ArgumentError, ~r/max_selections/, fn ->
        Navigation.context_selector(selector_id: "context", max_selections: 0)
      end
    end
  end
end
