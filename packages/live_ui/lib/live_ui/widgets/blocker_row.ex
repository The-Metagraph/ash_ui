defmodule LiveUi.Widgets.BlockerRow do
  @moduledoc """
  Single actionable blocker row for use inside `needs_you_section`.

  Renders as a `<button>` (full keyboard and screen-reader semantics) with:
  - Actor display: initials or image avatar (decorative, `aria-hidden`)
  - Body: `ask_text` + `scope_label` as the accessible button label
  - Jump affordance: visual arrow (aria-hidden)

  Severity is expressed via `data-severity` + a modifier class. The attribute
  is also useful as a CSS hook for host-level style overrides.

  ARIA: `aria-label` is constructed from `"{ask_text} — {scope_label}"` so
  screen-readers hear the full context. The avatar and jump arrow are both
  decorative.

  Open questions flagged in PR for Pascal review:
  - Row family: `:row_and_artifact` (current) vs `:content_identity_and_disclosure`?
  - Avatar inline vs child IUR: current draft inlines actor.avatar attrs inline.
  - Severity granularity: `[:info, :warn, :critical]` vs workflow-specific atoms?
  """

  use LiveUi.Component,
    family: :row_and_artifact,
    name: :blocker_row,
    events: [:click]

  LiveUi.Component.common_attrs()
  attr(:row_id, :string, required: true)
  attr(:ask_text, :string, required: true)
  attr(:scope_label, :string, required: true)
  attr(:severity, :string, default: "info")
  attr(:actor, :map, default: %{})
  attr(:interaction_attrs, :map, default: %{})

  @impl true
  def render(assigns) do
    actor_initials =
      get_in(assigns.actor, [:initials]) || get_in(assigns.actor, ["initials"]) || ""

    actor_image =
      get_in(assigns.actor, [:image_source]) || get_in(assigns.actor, ["image_source"])

    actor_name =
      get_in(assigns.actor, [:actor_name]) || get_in(assigns.actor, ["actor_name"]) || "Actor"

    aria_label = "#{assigns.ask_text} — #{assigns.scope_label}"

    assigns =
      assign(assigns, :actor_initials, actor_initials)
      |> assign(:actor_image, actor_image)
      |> assign(:actor_name, actor_name)
      |> assign(:aria_label, aria_label)

    ~H"""
    <button
      id={@id}
      type="button"
      data-live-ui-widget="blocker-row"
      data-row-id={@row_id}
      data-severity={@severity}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={["live-ui-blocker-row", "live-ui-blocker-row--#{@severity}", @class]}
      aria-label={@aria_label}
      {@interaction_attrs}
      {@rest}
    >
      <span class="live-ui-blocker-row__avatar" aria-hidden="true">
        <%= if @actor_image do %>
          <img src={@actor_image} alt="" class="live-ui-blocker-row__avatar-image" />
        <% else %>
          <span class="live-ui-blocker-row__avatar-initials">{@actor_initials}</span>
        <% end %>
      </span>
      <span class="live-ui-blocker-row__actor-name" aria-hidden="true">{@actor_name}</span>
      <div class="live-ui-blocker-row__body">
        <span class="live-ui-blocker-row__ask">{@ask_text}</span>
        <span class="live-ui-blocker-row__scope">{@scope_label}</span>
      </div>
      <span class="live-ui-blocker-row__jump" aria-hidden="true">jump</span>
    </button>
    """
  end
end
