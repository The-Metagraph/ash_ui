defmodule LiveUi.Widgets.SidebarSection do
  @moduledoc """
  Native renderer for the canonical `:sidebar_section` layer shell component.

  Sections are always-expanded by default. When `collapsible?` is true the
  header becomes an interactive button following the ARIA disclosure pattern
  (`aria-expanded` + `aria-controls`), and `expanded?` controls the visible
  state of the section body. The widget receives renderer-supplied interaction
  attributes and does not own Phoenix event names.
  """

  use LiveUi.Component,
    family: :layer_shell_and_callout,
    name: :sidebar_section,
    events: [:change]

  LiveUi.Component.common_attrs()
  attr(:label, :string, required: true)
  attr(:collapsible?, :boolean, default: false)
  attr(:expanded?, :boolean, default: true)
  attr(:action_label, :string, default: nil)
  attr(:action_glyph, :string, default: nil)
  attr(:action_intent, :any, default: nil)
  attr(:toggle_attrs, :map, default: %{})
  attr(:action_attrs, :map, default: %{})

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
            type="button"
            class="live-ui-sidebar-section-toggle"
            role="button"
            aria-expanded={to_string(@expanded?)}
            aria-controls={@section_body_id}
            {@toggle_attrs}
          >
            <span class="live-ui-sidebar-section-label">{@label}</span>
            <span class="live-ui-sidebar-section-indicator" aria-hidden="true">
              <%= if @expanded?, do: "-", else: "+" %>
            </span>
          </button>
          <%= if @action_intent do %>
            <button type="button" class="live-ui-sidebar-section-action" {@action_attrs}>
              {@action_label || @action_glyph || "+"}
            </button>
          <% end %>
        <% else %>
          <h3 class="live-ui-sidebar-section-label">{@label}</h3>
          <%= if @action_intent do %>
            <button type="button" class="live-ui-sidebar-section-action" {@action_attrs}>
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
