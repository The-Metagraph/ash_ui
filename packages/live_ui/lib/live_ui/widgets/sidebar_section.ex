defmodule LiveUi.Widgets.SidebarSection do
  @moduledoc """
  Sidebar section widget — a labeled group inside a sidebar shell.

  Sections are always-expanded by default. When `collapsible?` is true the
  header becomes an interactive button following the ARIA disclosure pattern
  (`aria-expanded` + `aria-controls`), and `expanded?` controls the visible
  state of the section body.

  ## Collapsible behaviour

  When `collapsible?` is true:

  - The `<h3>` label is replaced by a `<button>` with `role="button"`,
    `aria-expanded={@expanded?}`, and `aria-controls` pointing to the section
    body element id.
  - The section body `<div>` gets the matching `id` attribute.
  - A chevron indicator (`▼`/`▶`) is appended to the header button label
    (right-side of label, per comp audit SB-6).
  - The `on_toggle` event fires on click when supplied; otherwise the standard
    `phx-click="ui_relationship_toggle_section"` convention is used.
  - `expanded?: false` hides the section body via the
    `live-ui-sidebar-section-body--collapsed` CSS class (renderers are
    responsible for the actual visibility / animation via this hook class).

  ## Open design questions for Pascal

  1. **Compose vs. extend**: should this widget compose `:disclosure` internally
     once ash_ui PR #117 merges? Current implementation extends `:sidebar_section`
     directly because `:disclosure` is still DRAFT. Composition would be a
     non-breaking follow-up after PR #117 is approved.
  2. **Click target**: whole header or chevron only? Full-header is used here for
     better UX; revisit if header actions conflict.
  3. **Animation**: the `live-ui-sidebar-section-body--collapsed` CSS hook is
     provided; CSS transition handling is deferred to the theme layer.
  4. **`expanded?` persistence**: currently pure prop (no local-storage wiring);
     persistence is a host concern, not a widget concern.
  5. **Nested collapse**: only one level of collapse is modelled here; nested
     sub-sections collapse independently via their own `collapsible?`/`expanded?`.
  """

  use LiveUi.Component,
    family: :layer_shell_and_callout,
    name: :sidebar_section,
    events: [:toggle]

  LiveUi.Component.common_attrs()
  attr(:label, :string, required: true)
  attr(:collapsible?, :boolean, default: false)
  attr(:expanded?, :boolean, default: true)
  attr(:on_toggle, :string, default: nil)
  attr(:action_label, :string, default: nil)
  attr(:action_glyph, :string, default: nil)
  attr(:action_intent, :string, default: nil)

  slot(:inner_block)

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :section_body_id, "#{assigns.id}-body")

    ~H"""
    <section
      id={@id}
      class={["live-ui-sidebar-section", @class]}
      data-live-ui-widget="sidebar-section"
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      data-live-ui-collapsible={@collapsible?}
      data-live-ui-expanded={@expanded?}
      {@rest}
    >
      <div class="live-ui-sidebar-section-header">
        <%= if @collapsible? do %>
          <button
            class="live-ui-sidebar-section-toggle"
            role="button"
            aria-expanded={to_string(@expanded?)}
            aria-controls={@section_body_id}
            phx-click={@on_toggle || "ui_relationship_toggle_section"}
            phx-value-section-id={@id}
          >
            <span class="live-ui-sidebar-section-label">{@label}</span>
            <span class="live-ui-sidebar-section-chevron" aria-hidden="true">
              <%= if @expanded?, do: "▼", else: "▶" %>
            </span>
          </button>
          <%= if @action_intent do %>
            <button class="live-ui-sidebar-section-action">
              {@action_label || @action_glyph || "+"}
            </button>
          <% end %>
        <% else %>
          <h3 class="live-ui-sidebar-section-label">{@label}</h3>
          <%= if @action_intent do %>
            <button class="live-ui-sidebar-section-action">
              {@action_label || @action_glyph || "+"}
            </button>
          <% end %>
        <% end %>
      </div>
      <div
        id={@section_body_id}
        class={[
          "live-ui-sidebar-section-body",
          if(not @expanded?, do: "live-ui-sidebar-section-body--collapsed")
        ]}
        aria-hidden={if @collapsible?, do: to_string(not @expanded?), else: nil}
      >
        <%= render_slot(@inner_block) %>
      </div>
    </section>
    """
  end
end
