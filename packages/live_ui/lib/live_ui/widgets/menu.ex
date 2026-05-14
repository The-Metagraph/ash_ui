defmodule LiveUi.Widgets.Menu do
  @moduledoc """
  Baseline native menu widget.
  """

  use LiveUi.Component, family: :navigation, name: :menu, events: [:click]

  LiveUi.Component.common_attrs()
  attr(:items, :list, default: [])
  attr(:orientation, :string, default: "vertical")
  attr(:active_item, :string, default: nil)

  @impl true
  def render(assigns) do
    ~H"""
    <nav
      id={@id}
      data-live-ui-widget="menu"
      data-live-ui-orientation={@orientation}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    >
      <ul>
        <%= for item <- @items do %>
          <li data-active={to_string(item[:id]) == @active_item}>
            <button
              type="button"
              disabled={item[:disabled]}
              data-item-id={item[:id]}
              class={item[:class]}
              {Map.get(item, :attrs, %{})}
            >
              <%= item[:label] %>
            </button>
          </li>
        <% end %>
      </ul>
    </nav>
    """
  end
end
