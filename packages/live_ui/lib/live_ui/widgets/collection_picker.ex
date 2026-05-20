defmodule LiveUi.Widgets.CollectionPicker do
  @moduledoc """
  Native renderer for the canonical `:collection_picker` form-control component.

  The widget consumes generic collection picker attributes and renderer-supplied
  interaction attrs. It does not own product-specific bundle language, routes,
  or Phoenix event names in its canonical data model.
  """

  use LiveUi.Component,
    family: :form_control_and_composer,
    name: :collection_picker,
    events: [:change, :selection, :command]

  LiveUi.Component.common_attrs()

  attr(:picker_id, :string, required: true)
  attr(:title, :string, default: nil)
  attr(:query, :string, default: "")
  attr(:placeholder, :string, default: "Search collection")
  attr(:filters, :list, default: [])
  attr(:items, :list, default: [])
  attr(:suggestions, :list, default: [])
  attr(:empty_label, :string, default: "No matching items.")
  attr(:loading?, :boolean, default: false)
  attr(:density, :any, default: nil)
  attr(:query_attrs, :map, default: %{})
  attr(:filter_attrs, :map, default: %{})
  attr(:item_attrs, :map, default: %{})
  attr(:suggestion_accept_attrs, :map, default: %{})
  attr(:suggestion_dismiss_attrs, :map, default: %{})

  @impl true
  def render(assigns) do
    ~H"""
    <section
      id={@id}
      class={["live-ui-collection-picker", @class]}
      data-live-ui-widget="collection-picker"
      data-picker-id={@picker_id}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      data-live-ui-density={@density}
      role="region"
      aria-label={@title || "Collection picker"}
      {@rest}
    >
      <header :if={@title} class="live-ui-collection-picker__header">
        <h3 class="live-ui-collection-picker__title">{@title}</h3>
      </header>

      <div class="live-ui-collection-picker__search">
        <input
          type="search"
          name="query"
          value={@query}
          placeholder={@placeholder}
          aria-label={@placeholder}
          class="live-ui-collection-picker__search-input"
          {@query_attrs}
        />
      </div>

      <div
        :if={@filters != []}
        class="live-ui-collection-picker__filters"
        role="group"
        aria-label="Collection filters"
      >
        <button
          :for={filter <- @filters}
          type="button"
          class={[
            "live-ui-collection-picker__filter",
            selected?(filter) && "is-selected"
          ]}
          aria-pressed={selected_label(filter)}
          disabled={disabled?(filter)}
          data-filter-id={entry_id(filter)}
          {Map.get(@filter_attrs, entry_key(filter), %{})}
        >
          <span>{entry_label(filter)}</span>
          <span :if={entry_count(filter)} class="live-ui-collection-picker__filter-count">
            {entry_count(filter)}
          </span>
        </button>
      </div>

      <div :if={@loading?} class="live-ui-collection-picker__loading" aria-busy="true">
        Loading
      </div>

      <ul
        :if={@items != []}
        class="live-ui-collection-picker__items"
        role="listbox"
        aria-label="Collection items"
      >
        <li
          :for={item <- @items}
          class={[
            "live-ui-collection-picker__item",
            selected?(item) && "is-selected",
            disabled?(item) && "is-disabled"
          ]}
          role="option"
          aria-selected={selected_label(item)}
          data-item-id={entry_id(item)}
        >
          <button
            type="button"
            class="live-ui-collection-picker__item-button"
            disabled={disabled?(item)}
            {Map.get(@item_attrs, entry_key(item), %{})}
          >
            <span class="live-ui-collection-picker__item-label">{entry_label(item)}</span>
            <span
              :if={entry_description(item)}
              class="live-ui-collection-picker__item-description"
            >
              {entry_description(item)}
            </span>
          </button>
        </li>
      </ul>

      <div
        :if={@items == [] and not @loading?}
        class="live-ui-collection-picker__empty"
        role="status"
      >
        {@empty_label}
      </div>

      <div
        :if={@suggestions != []}
        class="live-ui-collection-picker__suggestions"
        aria-label="Suggestions"
      >
        <article
          :for={suggestion <- @suggestions}
          class="live-ui-collection-picker__suggestion"
          data-suggestion-id={entry_id(suggestion)}
        >
          <div class="live-ui-collection-picker__suggestion-body">
            <span class="live-ui-collection-picker__suggestion-label">
              {entry_label(suggestion)}
            </span>
            <span
              :if={entry_description(suggestion)}
              class="live-ui-collection-picker__suggestion-description"
            >
              {entry_description(suggestion)}
            </span>
            <span :if={suggestion_source(suggestion)} class="live-ui-collection-picker__suggestion-source">
              {suggestion_source(suggestion)}
            </span>
          </div>
          <div class="live-ui-collection-picker__suggestion-actions">
            <button
              type="button"
              class="live-ui-collection-picker__suggestion-accept"
              disabled={disabled?(suggestion)}
              {Map.get(@suggestion_accept_attrs, entry_key(suggestion), %{})}
            >
              Accept
            </button>
            <button
              type="button"
              class="live-ui-collection-picker__suggestion-dismiss"
              disabled={disabled?(suggestion)}
              {Map.get(@suggestion_dismiss_attrs, entry_key(suggestion), %{})}
            >
              Dismiss
            </button>
          </div>
        </article>
      </div>
    </section>
    """
  end

  defp entry_id(entry), do: field(entry, :id)
  defp entry_label(entry), do: field(entry, :label, entry_id(entry))
  defp entry_description(entry), do: field(entry, :description)
  defp entry_count(entry), do: field(entry, :count)
  defp suggestion_source(entry), do: field(entry, :source)
  defp entry_key(entry), do: entry_id(entry) |> normalize_key()
  defp selected_label(entry), do: if(selected?(entry), do: "true", else: "false")
  defp selected?(entry), do: field(entry, :selected?, false) || field(entry, :selected, false)
  defp disabled?(entry), do: field(entry, :disabled?, false) || field(entry, :disabled, false)

  defp field(entry, key, default \\ nil)

  defp field(entry, key, default) when is_map(entry),
    do: Map.get(entry, key, Map.get(entry, to_string(key), default))

  defp field(entry, key, default) when is_list(entry), do: Keyword.get(entry, key, default)
  defp field(_entry, _key, default), do: default

  defp normalize_key(nil), do: "item"

  defp normalize_key(value) do
    value
    |> to_string()
    |> String.replace(~r/[^a-zA-Z0-9_-]+/, "-")
  end
end
