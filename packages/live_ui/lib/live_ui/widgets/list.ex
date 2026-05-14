defmodule LiveUi.Widgets.List do
  @moduledoc """
  Native list widget for structured collections.
  """

  use LiveUi.Component, family: :data, name: :list, events: [:click, :selection]

  LiveUi.Component.common_attrs()
  attr(:items, :list, default: [])
  attr(:ordered, :boolean, default: false)
  attr(:selection_mode, :string, default: "single")

  @impl true
  def render(assigns) do
    ~H"""
    <section
      id={@id}
      data-live-ui-widget="list"
      data-live-ui-selection-mode={@selection_mode}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    >
      <%= if @ordered do %>
        <ol>
          <%= for item <- @items do %>
            <li
              data-item-id={fetch(item, :id)}
              data-selected={selected?(item)}
              class={fetch(item, :class)}
              {fetch(item, :attrs) || %{}}
            >
              <span><%= fetch(item, :label) || fetch(item, :value) %></span>
              <small :if={fetch(item, :description)}><%= fetch(item, :description) %></small>
            </li>
          <% end %>
        </ol>
      <% else %>
        <ul>
          <%= for item <- @items do %>
            <li
              data-item-id={fetch(item, :id)}
              data-selected={selected?(item)}
              class={fetch(item, :class)}
              {fetch(item, :attrs) || %{}}
            >
              <span><%= fetch(item, :label) || fetch(item, :value) %></span>
              <small :if={fetch(item, :description)}><%= fetch(item, :description) %></small>
            </li>
          <% end %>
        </ul>
      <% end %>
    </section>
    """
  end

  defp selected?(item) do
    fetch(item, :selected) || fetch(item, :selected?)
  end

  defp fetch(item, key) when is_map(item) do
    Map.get(item, key) || Map.get(item, Atom.to_string(key))
  end
end
