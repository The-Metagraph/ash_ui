defmodule LiveUi.Widgets.SegmentedButtonGroup do
  @moduledoc """
  Native segmented button group widget.

  Renders a canonical single-selection segmented control as a radiogroup.

  ## Canonical contract

  Segmented button group is part of `:form_control_and_composer`. Canonical
  data arrives through `attributes.selection.options`, `active_value`, and
  `selection_intent`; renderer-specific event attributes are supplied per
  option in `:attrs`. Multi-select semantics are intentionally out of scope for
  this primitive because they require a different ARIA and selected-state model.
  """

  use LiveUi.Component,
    family: :form_control_and_composer,
    name: :segmented_button_group,
    events: [:selection]

  LiveUi.Component.common_attrs()
  attr(:options, :list, required: true, doc: "List of maps with :value and :label keys")
  attr(:selected_value, :any, default: nil, doc: "Currently selected value")
  attr(:label, :string, required: true, doc: "aria-label for the radiogroup container")

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      class={["live-ui-segmented-button-group", @class]}
      data-live-ui-widget="segmented_button_group"
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      role="radiogroup"
      aria-label={@label}
      {@rest}
    >
      <button
        :for={option <- @options}
        type="button"
        role="radio"
        aria-checked={selected_value(option, @selected_value)}
        disabled={option_disabled?(option)}
        class={["live-ui-segmented-button-group-option", option_selected?(option, @selected_value) && "is-selected"]}
        data-option-value={option_value(option)}
        {option_attrs(option)}
      >
        {option_label(option)}
      </button>
    </div>
    """
  end

  defp option_value(option), do: fetch_option(option, :value)
  defp option_label(option), do: fetch_option(option, :label, "")
  defp option_attrs(option), do: fetch_option(option, :attrs, %{})

  defp option_disabled?(option) do
    fetch_option(option, :disabled?) || fetch_option(option, :disabled) || false
  end

  defp option_selected?(option, selected_value) do
    to_string(option_value(option)) == to_string(selected_value)
  end

  defp selected_value(option, selected_value) do
    if option_selected?(option, selected_value), do: "true", else: "false"
  end

  defp fetch_option(option, key, default \\ nil)
  defp fetch_option(option, key, default) when is_map(option), do: Map.get(option, key, default)

  defp fetch_option(option, key, default) when is_list(option),
    do: Keyword.get(option, key, default)

  defp fetch_option(_option, _key, default), do: default
end
