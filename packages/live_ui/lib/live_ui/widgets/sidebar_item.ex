defmodule LiveUi.Widgets.SidebarItem do
  @moduledoc """
  Native sidebar-item widget.

  Renders a navigable sidebar list item with selected state, intent, and optional
  badge children. Extends the base `:sidebar_item` with:

  - `avatar_url` — optional URL for a small avatar image rendered before the label.
    When `nil` (default), no image is rendered. The `<img>` is `aria-hidden="true"`
    because the label already provides the accessible name.
  - `item_state` — optional workflow state atom (`:default`, `:stalled`, `:blocked`,
    `:errored`). When `nil` (default), no extra state modifier class is applied.
    State is exposed as a BEM modifier class (`live-ui-sidebar-item--state-{value}`)
    and as a `data-live-ui-item-state` hook attribute for CSS/JS targeting.

  ## Attributes

  Required:
  - `:id` - element identifier
  - `:label` - display text for the item

  Optional:
  - `:selected?` - boolean; adds `--selected` BEM modifier and `aria-current="page"` (default `false`)
  - `:avatar_url` - URL string; when present, renders `<img aria-hidden="true">` before label (default `nil`)
  - `:item_state` - atom; one of `:default | :stalled | :blocked | :errored` (default `nil`)
  - `:item_intent` - canonical Interaction intent for click events (default `nil`)

  ## Selector / hook contract

  Root `<li>`: `data-live-ui-widget="sidebar-item"` + `data-live-ui-item-state="{state}"` (omitted when nil).
  Button: `.live-ui-sidebar-item-button`.
  Avatar (when present): `.live-ui-sidebar-item__avatar` + `aria-hidden="true"`.
  State modifier on root: `live-ui-sidebar-item--state-{stalled|blocked|errored}`.

  ## ARIA

  - `aria-current="page"` on the inner button when `selected?` is `true`.
  - Avatar `<img>` carries `aria-hidden="true"` since the sibling label text is the
    accessible name; no `alt` text needed.
  - `:blocked` items remain clickable by default (no `aria-disabled`). Pascal may
    add `aria-disabled="true"` in a follow-up once the UX intent is confirmed
    (open question #4 in unified_ui #184).

  ## Open questions for Pascal (unified_ui #184)

  1. **Avatar composition** — currently renders `<img>` inline (smallest delta). If the
     `:avatar` canonical widget (ash_ui PR #116) stabilises before this is adopted, prefer
     composing via that widget for DRY rendering.
  2. **State enum completeness** — `:stalled | :blocked | :errored` are the audit-required
     values. `:loading` / `:in_progress` deferred pending Pascal confirmation.
  3. **`state` vs `tone`** — `item_state` is named to avoid collision with the `LiveUi.Component`
     common `:state` assign (style-hook). Pascal may prefer a different name.
  4. **ARIA for `:blocked`** — `aria-disabled="true"` deferred; comp shows visual treatment
     but intent unclear (still-clickable vs truly disabled).
  5. **Avatar fallback** — initials fallback for missing `avatar_url` on DM rows is
     consumer-side; out of scope for this extension.
  """

  use LiveUi.Component, family: :content, name: :sidebar_item, events: [:click]

  LiveUi.Component.common_attrs()
  attr(:label, :string, required: true)
  attr(:selected?, :boolean, default: false)
  attr(:avatar_url, :string, default: nil)
  attr(:item_state, :atom, default: nil)
  attr(:item_intent, :string, default: nil)

  slot(:inner_block)

  @impl true
  def render(assigns) do
    ~H"""
    <li
      id={@id}
      data-live-ui-widget="sidebar-item"
      data-live-ui-item-state={if @item_state && @item_state != :default, do: to_string(@item_state)}
      class={[
        "live-ui-sidebar-item",
        if(@selected?, do: "live-ui-sidebar-item--selected"),
        state_modifier_class(@item_state),
        @class
      ]}
      {@rest}
    >
      <button
        class="live-ui-sidebar-item-button"
        aria-current={if @selected?, do: "page"}
        data-live-ui-intent={@item_intent}
      >
        <%= if @avatar_url do %>
          <img
            class="live-ui-sidebar-item__avatar"
            src={@avatar_url}
            aria-hidden="true"
          />
        <% end %>
        {@label}
        <%= render_slot(@inner_block) %>
      </button>
    </li>
    """
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp state_modifier_class(nil), do: nil
  defp state_modifier_class(:default), do: nil
  defp state_modifier_class(state), do: "live-ui-sidebar-item--state-#{state}"
end
