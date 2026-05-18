defmodule LiveUi.Widgets.ListRepeat do
  @moduledoc """
  Stage-4 Phoenix.Component for the `:list_repeat` composition behavior primitive.

  ListRepeat is a structural container, not a decorative visual widget. It
  iterates over a pre-hydrated list of child elements and renders each using
  the canonical IUR renderer. The hydration pass (via `AshUI.LiveView.IURHydration`)
  runs upstream and produces concrete `Element.t()` children before this
  component is called.

  Design questions for Pascal — see ash_ui PR body for the full 6-question set.

  ## Usage (from renderer)

      <LiveUi.Widgets.ListRepeat.component
        id="repeat-users"
        items={hydrated_row_elements}
        repeat_binding="users"
        ...
      />

  ## Slot model

  Uses a single `:row` slot rendered once per item, receiving the hydrated
  `Element.t()` child element via `:let`. An optional `:empty_state` slot is
  rendered when `items` is empty.

  ## Attrs

  - `id` (required, string)
  - `items` (required, list) — pre-hydrated `Element.t()` children, one per row
  - `repeat_binding` (optional, string) — data-attr echoing the IUR binding_id,
    for CSS-hook / selector continuity with current fallback shape
  - `empty_state` (optional slot) — rendered when items list is empty

  ## Classification

  Per Pascal's widget skill: **Composition behavior** — structural repeat/list
  composition. Modeled as canonical intent; no decorative visual styling.
  Family: `:composition_behavior`.
  """

  use LiveUi.Component,
    family: :composition_behavior,
    name: :list_repeat,
    slots: [:row, :empty_state]

  LiveUi.Component.common_attrs()
  attr(:items, :list, required: true, doc: "Pre-hydrated row elements (one per iteration)")

  attr(:repeat_binding, :string,
    default: nil,
    doc: "Echo of the IUR binding_id for CSS-hook / data-attr continuity"
  )

  slot(:row, required: false, doc: "Template rendered once per item; receives item via :let")
  slot(:empty_state, required: false, doc: "Rendered when items list is empty")

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      data-live-ui-widget="list-repeat"
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      data-repeat-binding={@repeat_binding}
      class={@class}
      {@rest}
    >
      <%= if @items == [] do %>
        <%= render_slot(@empty_state) %>
      <% else %>
        <%= for item <- @items do %>
          <%= render_slot(@row, item) %>
        <% end %>
      <% end %>
    </div>
    """
  end
end
