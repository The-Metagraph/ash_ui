defmodule LiveUi.Widgets.ContextSelector do
  @moduledoc """
  Native grouped context selector widget.
  """

  use LiveUi.Component,
    family: :navigation,
    name: :context_selector,
    events: [:selection, :change]

  LiveUi.Component.common_attrs()
  attr(:selector_id, :string, required: true)
  attr(:groups, :list, default: [])
  attr(:placeholder, :string, default: "Select context...")
  attr(:selected_values, :list, default: [])
  attr(:max_selections, :any, default: 1)
  attr(:label_prefix, :string, default: "context:")
  attr(:open?, :boolean, default: false)
  attr(:disabled?, :boolean, default: false)

  @impl true
  def render(assigns) do
    summary = trigger_summary(assigns.selected_values, assigns.groups, assigns.placeholder)

    assigns =
      assigns
      |> assign(:summary, summary)
      |> assign(:multi?, multi?(assigns.max_selections))

    ~H"""
    <div
      id={@id}
      class={["live-ui-context-selector", @class, @disabled? && "is-disabled"]}
      data-live-ui-widget="context-selector"
      data-selector-id={@selector_id}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      {@rest}
    >
      <button
        type="button"
        id={"#{@selector_id}-trigger"}
        class={["live-ui-context-selector__trigger", @open? && "is-open"]}
        aria-haspopup="listbox"
        aria-expanded={to_string(@open?)}
        aria-controls={"#{@selector_id}-panel"}
        aria-label={"#{@label_prefix} #{@summary}"}
        disabled={@disabled?}
      >
        <span class="live-ui-context-selector__prefix">{@label_prefix}</span>
        <span class="live-ui-context-selector__summary">{@summary}</span>
        <span class="live-ui-context-selector__caret" aria-hidden="true">v</span>
      </button>

      <div
        :if={@open?}
        id={"#{@selector_id}-panel"}
        class="live-ui-context-selector__panel"
        role="listbox"
        aria-labelledby={"#{@selector_id}-trigger"}
        aria-multiselectable={to_string(@multi?)}
      >
        <div :for={group <- @groups} class="live-ui-context-selector__group" role="group" aria-label={group_label(group)}>
          <div class="live-ui-context-selector__group-header">{group_label(group)}</div>

          <button
            :for={item <- group_items(group)}
            type="button"
            role="option"
            aria-selected={to_string(item_selected?(item, @selected_values))}
            disabled={item_disabled?(item)}
            class={[
              "live-ui-context-selector__item",
              item_selected?(item, @selected_values) && "is-selected"
            ]}
            data-context-value={item_value(item)}
            {item_attrs(item)}
          >
            <span class="live-ui-context-selector__item-indicator" aria-hidden="true">
              {if item_selected?(item, @selected_values), do: "[x]", else: "[ ]"}
            </span>
            <span class="live-ui-context-selector__item-body">
              <span class="live-ui-context-selector__item-label">{item_label(item)}</span>
              <span :if={item_description(item)} class="live-ui-context-selector__item-description">
                {item_description(item)}
              </span>
            </span>
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp trigger_summary([], _groups, placeholder), do: placeholder

  defp trigger_summary([value], groups, _placeholder) do
    find_item_label(value, groups) || to_string(value)
  end

  defp trigger_summary(values, _groups, _placeholder), do: "#{length(values)} selected"

  defp find_item_label(value, groups) do
    groups
    |> Enum.flat_map(&group_items/1)
    |> Enum.find(&(to_string(item_value(&1)) == to_string(value)))
    |> case do
      nil -> nil
      item -> item_label(item)
    end
  end

  defp multi?(:unlimited), do: true
  defp multi?("unlimited"), do: true
  defp multi?(value) when is_integer(value), do: value > 1
  defp multi?(value) when is_binary(value), do: value |> Integer.parse() |> numeric_multi?()
  defp multi?(_value), do: false

  defp numeric_multi?({value, ""}), do: value > 1
  defp numeric_multi?(_value), do: false

  defp group_items(group), do: fetch(group, :items, [])
  defp group_label(group), do: fetch(group, :label, "")
  defp item_value(item), do: fetch(item, :value)
  defp item_label(item), do: fetch(item, :label, to_string(item_value(item)))
  defp item_description(item), do: fetch(item, :description)
  defp item_attrs(item), do: fetch(item, :attrs, %{})

  defp item_disabled?(item) do
    fetch(item, :disabled?) || fetch(item, :disabled) || false
  end

  defp item_selected?(item, selected_values) do
    Enum.any?(selected_values, &(to_string(&1) == to_string(item_value(item)))) ||
      fetch(item, :selected?, false)
  end

  defp fetch(source, key, default \\ nil)
  defp fetch(source, key, default) when is_map(source), do: Map.get(source, key, default)
  defp fetch(source, key, default) when is_list(source), do: Keyword.get(source, key, default)
  defp fetch(_source, _key, default), do: default
end
