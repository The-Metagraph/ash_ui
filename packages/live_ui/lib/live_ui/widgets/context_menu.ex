defmodule LiveUi.Widgets.ContextMenu do
  @moduledoc """
  Native context-menu widget anchored to a target region.
  """

  use LiveUi.Component, family: :overlay, name: :context_menu, events: [:click]

  LiveUi.Component.common_attrs()
  attr(:items, :list, default: [])
  attr(:open, :boolean, default: true)
  attr(:placement, :string, default: "bottom-start")
  attr(:anchor, :map, default: %{})
  attr(:active_item, :string, default: nil)

  @impl true
  def render(assigns) do
    assigns =
      assign(
        assigns,
        :diagnostics,
        LiveUi.Diagnostics.validate_context_menu(assigns.anchor, assigns.items)
      )

    ~H"""
    <nav
      id={@id}
      data-live-ui-widget="context-menu"
      data-live-ui-open={@open}
      data-live-ui-placement={@placement}
      data-live-ui-anchor-x={anchor_value(@anchor, :x)}
      data-live-ui-anchor-y={anchor_value(@anchor, :y)}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    >
      <LiveUi.Diagnostics.render diagnostics={@diagnostics} />
      <ul>
        <%= for item <- @items do %>
          <li data-active={to_string(item[:id]) == @active_item}>
            <button type="button" disabled={item[:disabled]} data-item-id={item[:id]}>
              <%= item[:label] %>
            </button>
          </li>
        <% end %>
      </ul>
    </nav>
    """
  end

  defp anchor_value(anchor, key) do
    Map.get(anchor, key) || Map.get(anchor, Atom.to_string(key))
  end
end
