defmodule DesktopUi.Widgets.Navigation do
  @moduledoc """
  Foundational navigation widgets for direct-native `desktop_ui`.

  This module provides both widget constructors for navigation widgets
  (menu, tabs, breadcrumbs, list) and helpers for integrating with
  the screen navigation system.

  ## Screen Navigation

  Screen navigation allows widgets to emit navigation signals that
  are routed to the navigation controller for screen transitions.

      # Navigate to another screen on button click
      button = DesktopUi.Widgets.button("Go to Detail",
        navigate_to: :detail,
        navigate_params: %{item_id: 123}
      )

      # Navigate with replace
      DesktopUi.Widgets.button("Show Error",
        replace_with: :error,
        navigate_params: %{code: 404}
      )

      # Go back button
      DesktopUi.Widgets.button("Back", go_back: true)

      # Open modal
      DesktopUi.Widgets.button("Confirm",
        open_modal: :confirm_dialog,
        navigate_params: %{message: "Are you sure?"}
      )

  """

  alias DesktopUi.Widget
  alias DesktopUi.Navigation.Signal

  @spec kinds() :: [atom()]
  def kinds do
    [:breadcrumbs, :list, :menu, :tabs]
  end

  @spec tabs(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def tabs(id, items, opts \\ []) do
    navigation_widget(:tabs, id, items, opts)
  end

  @spec menu(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def menu(id, items, opts \\ []) do
    navigation_widget(:menu, id, items, opts)
  end

  @spec breadcrumbs(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def breadcrumbs(id, items, opts \\ []) do
    navigation_widget(:breadcrumbs, id, items, opts)
  end

  @spec list(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def list(id, items, opts \\ []) do
    navigation_widget(:list, id, items, opts)
  end

  @doc """
  Creates a navigation signal for navigating to a screen.

  ## Options

  * `:navigate_to` - Screen ID to navigate to (adds to history)
  * `:replace_with` - Screen ID to replace current with (no history entry)
  * `:go_back` - Set to true to go back in history
  * `:go_forward` - Set to true to go forward in history
  * `:open_modal` - Screen ID to open as modal
  * `:close_modal` - Set to true to close top modal
  * `:navigate_params` - Params to pass with navigation

  ## Examples

      signal = Navigation.signal_for(navigate_to: :detail, navigate_params: %{item_id: 123})
      # => %Signal{type: :navigate_to, screen_id: :detail, params: %{item_id: 123}}

  """
  @spec signal_for(keyword()) :: Signal.t() | nil
  def signal_for(opts) when is_list(opts), do: opts |> Enum.into(%{}) |> signal_for()

  def signal_for(%{navigate_to: screen_id} = opts) when is_atom(screen_id) or is_binary(screen_id) do
    Signal.navigate(screen_id, Map.get(opts, :navigate_params, %{}))
  end

  def signal_for(%{replace_with: screen_id} = opts) when is_atom(screen_id) or is_binary(screen_id) do
    Signal.replace(screen_id, Map.get(opts, :navigate_params, %{}))
  end

  def signal_for(%{go_back: true}) do
    Signal.go_back()
  end

  def signal_for(%{go_forward: true}) do
    Signal.go_forward()
  end

  def signal_for(%{open_modal: screen_id} = opts) when is_atom(screen_id) or is_binary(screen_id) do
    Signal.open_modal(screen_id, Map.get(opts, :navigate_params, %{}))
  end

  def signal_for(%{close_modal: true}) do
    Signal.close_modal()
  end

  def signal_for(_), do: nil

  @doc """
  Returns the navigation event payload for a widget based on navigation options.

  This is used internally by widget builders to attach navigation events.

  ## Examples

      payload = Navigation.event_payload(navigate_to: :detail)
      # => %{family: :navigation, type: :navigate_to, screen_id: :detail}

  """
  @spec event_payload(keyword()) :: map() | nil
  def event_payload(opts) when is_list(opts), do: opts |> Enum.into(%{}) |> event_payload()

  def event_payload(%{navigate_to: screen_id} = opts) when is_atom(screen_id) or is_binary(screen_id) do
    %{
      family: :navigation,
      type: :navigate_to,
      screen_id: screen_id,
      params: Map.get(opts, :navigate_params, %{})
    }
  end

  def event_payload(%{replace_with: screen_id} = opts) when is_atom(screen_id) or is_binary(screen_id) do
    %{
      family: :navigation,
      type: :replace_with,
      screen_id: screen_id,
      params: Map.get(opts, :navigate_params, %{})
    }
  end

  def event_payload(%{go_back: true}) do
    %{family: :navigation, type: :go_back}
  end

  def event_payload(%{go_forward: true}) do
    %{family: :navigation, type: :go_forward}
  end

  def event_payload(%{open_modal: screen_id} = opts) when is_atom(screen_id) or is_binary(screen_id) do
    %{
      family: :navigation,
      type: :open_modal,
      screen_id: screen_id,
      params: Map.get(opts, :navigate_params, %{})
    }
  end

  def event_payload(%{close_modal: true}) do
    %{family: :navigation, type: :close_modal}
  end

  def event_payload(_), do: nil

  defp navigation_widget(kind, id, items, opts) do
    Widget.new(kind,
      id: id,
      metadata:
        %{
          focusable: true,
          role: kind,
          shortcut: Keyword.get(opts, :shortcut),
          shortcut_scope: Keyword.get(opts, :shortcut_scope, :screen),
          focus_group: Keyword.get(opts, :focus_group, "#{id}:#{kind}")
        }
        |> Map.merge(Map.new(Keyword.get(opts, :metadata, []))),
      state: %{
        disabled: Keyword.get(opts, :disabled, false),
        focused: false,
        current: Keyword.get(opts, :current, Keyword.get(opts, :active_item))
      },
      bindings: %{current: Keyword.get(opts, :binding, :current)},
      attributes: %{
        items: Enum.map(items, &Map.new/1),
        current: Keyword.get(opts, :current, Keyword.get(opts, :active_item))
      },
      styles: Map.new(Keyword.get(opts, :styles, [])),
      events:
        %{
          navigation: Keyword.get(opts, :on_navigate, %{intent: :navigate}),
          selection: Keyword.get(opts, :on_select, %{intent: :select_navigation_item}),
          shortcut:
            shortcut_payload(
              Keyword.get(opts, :shortcut),
              Keyword.get(opts, :shortcut_intent, :open_navigation)
            )
        }
        |> Enum.reject(fn {_key, value} -> is_nil(value) end)
        |> Map.new()
    )
  end

  defp shortcut_payload(nil, _intent), do: nil

  defp shortcut_payload(shortcut, intent) do
    %{key: shortcut, intent: intent}
  end
end
