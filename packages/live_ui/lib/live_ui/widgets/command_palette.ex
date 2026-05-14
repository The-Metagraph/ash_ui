defmodule LiveUi.Widgets.CommandPalette do
  @moduledoc """
  Baseline native command palette widget.
  """

  use LiveUi.Component, family: :navigation, name: :command_palette, events: [:change, :submit]

  LiveUi.Component.common_attrs()
  attr(:query, :string, default: nil)
  attr(:items, :list, default: [])
  attr(:input_attrs, :map, default: %{})

  @impl true
  def render(assigns) do
    ~H"""
    <section
      id={@id}
      data-live-ui-widget="command-palette"
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    >
      <input type="text" name="command_query" value={@query} placeholder="Type a command" {@input_attrs} />
      <ul>
        <%= for item <- @items do %>
          <li data-command-id={item[:id]} data-active={item[:active]}>
            <button type="button" class={item[:class]} {Map.get(item, :attrs, %{})}>
              <%= item[:label] %>
            </button>
          </li>
        <% end %>
      </ul>
    </section>
    """
  end
end
