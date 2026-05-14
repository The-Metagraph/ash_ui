defmodule DesktopUi.Widgets.NavigationTest do
  use ExUnit.Case
  alias DesktopUi.Widgets.Navigation
  alias DesktopUi.Navigation.Signal

  @moduletag :navigation

  describe "signal_for/1" do
    test "creates navigate_to signal from keyword list" do
      signal = Navigation.signal_for(navigate_to: :detail, navigate_params: %{item_id: 123})

      assert %Signal{type: :navigate_to, screen_id: :detail, params: %{item_id: 123}} = signal
    end

    test "creates navigate_to signal from map" do
      signal = Navigation.signal_for(%{navigate_to: :detail, navigate_params: %{item_id: 456}})

      assert %Signal{type: :navigate_to, screen_id: :detail, params: %{item_id: 456}} = signal
    end

    test "creates replace_with signal" do
      signal = Navigation.signal_for(replace_with: :error, navigate_params: %{code: 404})

      assert %Signal{type: :replace_with, screen_id: :error, params: %{code: 404}} = signal
    end

    test "creates go_back signal" do
      signal = Navigation.signal_for(go_back: true)

      assert %Signal{type: :go_back, screen_id: nil, params: %{}} = signal
    end

    test "creates go_forward signal" do
      signal = Navigation.signal_for(go_forward: true)

      assert %Signal{type: :go_forward, screen_id: nil, params: %{}} = signal
    end

    test "creates open_modal signal" do
      signal = Navigation.signal_for(open_modal: :confirm_dialog, navigate_params: %{message: "OK"})

      assert %Signal{type: :open_modal, screen_id: :confirm_dialog, params: %{message: "OK"}} = signal
    end

    test "creates close_modal signal" do
      signal = Navigation.signal_for(close_modal: true)

      assert %Signal{type: :close_modal, screen_id: nil, params: %{}} = signal
    end

    test "returns nil for unknown navigation type" do
      assert nil == Navigation.signal_for(%{unknown: :value})
    end

    test "returns nil when go_back is false" do
      assert nil == Navigation.signal_for(%{go_back: false})
    end

    test "returns nil when go_forward is false" do
      assert nil == Navigation.signal_for(%{go_forward: false})
    end

    test "returns nil when close_modal is false" do
      assert nil == Navigation.signal_for(%{close_modal: false})
    end
  end

  describe "event_payload/1" do
    test "creates navigate_to event payload" do
      payload = Navigation.event_payload(navigate_to: :detail, navigate_params: %{item_id: 123})

      assert %{
        family: :navigation,
        type: :navigate_to,
        screen_id: :detail,
        params: %{item_id: 123}
      } = payload
    end

    test "creates replace_with event payload" do
      payload = Navigation.event_payload(replace_with: :error)

      assert %{
        family: :navigation,
        type: :replace_with,
        screen_id: :error,
        params: %{}
      } = payload
    end

    test "creates go_back event payload" do
      payload = Navigation.event_payload(go_back: true)

      assert %{family: :navigation, type: :go_back} = payload
    end

    test "creates go_forward event payload" do
      payload = Navigation.event_payload(go_forward: true)

      assert %{family: :navigation, type: :go_forward} = payload
    end

    test "creates open_modal event payload" do
      payload = Navigation.event_payload(open_modal: :settings)

      assert %{
        family: :navigation,
        type: :open_modal,
        screen_id: :settings,
        params: %{}
      } = payload
    end

    test "creates close_modal event payload" do
      payload = Navigation.event_payload(close_modal: true)

      assert %{family: :navigation, type: :close_modal} = payload
    end

    test "returns nil for unknown navigation type" do
      assert nil == Navigation.event_payload(%{unknown: :value})
    end

    test "includes navigate_params in payload" do
      payload = Navigation.event_payload(navigate_to: :detail, navigate_params: %{id: 1, mode: :edit})

      assert %{params: %{id: 1, mode: :edit}} = payload
    end
  end

  describe "navigation widgets" do
    test "tabs/3 creates a tabs widget" do
      items = [%{id: :tab1, label: "Tab 1"}, %{id: :tab2, label: "Tab 2"}]
      widget = Navigation.tabs(:main_tabs, items, active_item: :tab1)

      assert widget.kind == :tabs
      assert widget.id == :main_tabs
      assert widget.attributes.items == items
      assert widget.attributes.current == :tab1
      assert widget.metadata.role == :tabs
    end

    test "menu/3 creates a menu widget" do
      items = [%{id: :item1, label: "Item 1"}]
      widget = Navigation.menu(:context_menu, items)

      assert widget.kind == :menu
      assert widget.id == :context_menu
      assert widget.metadata.role == :menu
    end

    test "breadcrumbs/3 creates a breadcrumbs widget" do
      items = [%{id: :home, label: "Home"}, %{id: :section, label: "Section"}]
      widget = Navigation.breadcrumbs(:trail, items)

      assert widget.kind == :breadcrumbs
      assert widget.id == :trail
      assert widget.metadata.role == :breadcrumbs
    end

    test "list/3 creates a list widget" do
      items = [%{id: :item1, label: "Item 1"}, %{id: :item2, label: "Item 2"}]
      widget = Navigation.list(:item_list, items)

      assert widget.kind == :list
      assert widget.id == :item_list
      assert widget.metadata.role == :list
    end
  end
end
