defmodule LiveUi.Widgets.Tabs do
  @moduledoc """
  Baseline native tabs widget.
  """

  use LiveUi.Component, family: :navigation, name: :tabs, events: [:click, :navigate]

  LiveUi.Component.common_attrs()
  attr(:items, :list, default: [])
  attr(:active_item, :string, default: nil)

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      data-live-ui-widget="tabs"
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    >
      <div role="tablist">
        <%= for item <- @items do %>
          <%= render_tab_item(item, @active_item) %>
        <% end %>
      </div>
    </div>
    """
  end

  defp render_tab_item(item, active_item) do
    count = fetch_item(item, :count)

    assigns = %{
      item_id: fetch_item(item, :id),
      label: fetch_item(item, :label),
      count: count,
      selected?: item_selected?(item, active_item),
      disabled?: fetch_item(item, :disabled, false),
      item_class: fetch_item(item, :class),
      item_attrs: fetch_item(item, :attrs, %{}),
      target: item_target(item)
    }

    ~H"""
    <%= if @disabled? do %>
      <button
        type="button"
        role="tab"
        aria-selected={selected_value(@selected?)}
        tabindex={tab_index(@selected?)}
        disabled
        data-item-id={@item_id}
        class={@item_class}
        {@item_attrs}
      ><.tab_contents label={@label} count={@count} /></button>
    <% else %>
      <%= case @target do %>
        <% {:patch, target} -> %>
          <.link
            patch={target}
            role="tab"
            aria-selected={selected_value(@selected?)}
            tabindex={tab_index(@selected?)}
            data-item-id={@item_id}
            class={@item_class}
            {@item_attrs}
          ><.tab_contents label={@label} count={@count} /></.link>
        <% {:navigate, target} -> %>
          <.link
            navigate={target}
            role="tab"
            aria-selected={selected_value(@selected?)}
            tabindex={tab_index(@selected?)}
            data-item-id={@item_id}
            class={@item_class}
            {@item_attrs}
          ><.tab_contents label={@label} count={@count} /></.link>
        <% {:href, target} -> %>
          <.link
            href={target}
            role="tab"
            aria-selected={selected_value(@selected?)}
            tabindex={tab_index(@selected?)}
            data-item-id={@item_id}
            class={@item_class}
            {@item_attrs}
          ><.tab_contents label={@label} count={@count} /></.link>
        <% :button -> %>
          <button
            type="button"
            role="tab"
            aria-selected={selected_value(@selected?)}
            tabindex={tab_index(@selected?)}
            data-item-id={@item_id}
            class={@item_class}
            {@item_attrs}
          ><.tab_contents label={@label} count={@count} /></button>
      <% end %>
    <% end %>
    """
  end

  defp tab_contents(assigns) do
    ~H"""
    <span class="live-ui-tabs-item-label"><%= @label %></span>
    <span :if={not is_nil(@count)} class="live-ui-tabs-item-count"><%= @count %></span>
    """
  end

  defp item_selected?(_item, nil), do: false

  defp item_selected?(item, active_item) do
    to_string(fetch_item(item, :id)) == to_string(active_item)
  end

  defp item_target(item) do
    cond do
      target = fetch_item(item, :patch) -> {:patch, target}
      target = fetch_item(item, :navigate) -> {:navigate, target}
      target = fetch_item(item, :href) -> {:href, target}
      true -> :button
    end
  end

  defp fetch_item(item, key, default \\ nil)
  defp fetch_item(item, key, default) when is_map(item), do: Map.get(item, key, default)
  defp fetch_item(item, key, default) when is_list(item), do: Keyword.get(item, key, default)
  defp fetch_item(_item, _key, default), do: default

  defp selected_value(true), do: "true"
  defp selected_value(false), do: "false"

  defp tab_index(true), do: "0"
  defp tab_index(false), do: "-1"
end
