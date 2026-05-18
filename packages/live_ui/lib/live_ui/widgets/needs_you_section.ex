defmodule LiveUi.Widgets.NeedsYouSection do
  @moduledoc """
  Attention-needed band listing operator-facing blockers.

  Renders a titled section with a list of `blocker_row` children, an empty-state
  message when no items are present, and an overflow affordance when items exceed
  `max_visible`. Each row is rendered via `LiveUi.Renderer.render/1` so the parent
  decides row composition.

  ARIA: normal `<section>` with `<h2>` heading semantics. The count badge is
  `aria-hidden` — it is visual sugar on top of the heading, not an independent
  landmark.

  Open questions flagged in PR for Pascal review:
  - Section family: `:workflow_progress_and_status` (current) vs `:layer_shell_and_callout`?
  - `:expanded?` state: internal to widget or external (parent-driven)?
  """

  use LiveUi.Component,
    family: :workflow,
    name: :needs_you_section,
    events: [:click]

  LiveUi.Component.common_attrs()
  attr(:title, :string, default: "Needs you")
  attr(:empty_state_text, :string, default: "You're all caught up.")
  attr(:max_visible, :integer, default: 5)
  attr(:items, :list, default: [])
  attr(:event_target, :any, default: nil)

  @impl true
  def render(assigns) do
    visible = Enum.take(assigns.items, assigns.max_visible)
    overflow = length(assigns.items) - assigns.max_visible
    assigns = assign(assigns, :visible_items, visible) |> assign(:overflow_count, overflow)

    ~H"""
    <section
      id={@id}
      data-live-ui-widget="needs-you-section"
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={["live-ui-needs-you", @class]}
      {@rest}
    >
      <header class="live-ui-needs-you__header">
        <h2 class="live-ui-needs-you__title">{@title}</h2>
        <%= if @items != [] do %>
          <span class="live-ui-needs-you__count" aria-hidden="true">({length(@items)})</span>
        <% end %>
      </header>

      <%= if @items == [] do %>
        <p class="live-ui-needs-you__empty">{@empty_state_text}</p>
      <% else %>
        <ul class="live-ui-needs-you__list" role="list">
          <%= for item <- @visible_items do %>
            <li class="live-ui-needs-you__item">
              <LiveUi.Renderer.render element={item} event_target={@event_target} />
            </li>
          <% end %>
        </ul>
        <%= if @overflow_count > 0 do %>
          <button
            type="button"
            class="live-ui-needs-you__more"
            data-live-ui-intent="expand_needs_you_section"
          >
            show {@overflow_count} more
          </button>
        <% end %>
      <% end %>
    </section>
    """
  end
end
