defmodule LiveUi.Widgets.RepoProgressCard do
  @moduledoc """
  Native repo-progress-card widget.

  Composite card representing a single repository in a repo grid. Combines:
  - Header (name + optional path + optional contextual action button)
  - Progress bar with full ARIA progressbar semantics
  - Stat chips (active dispatches, blocked dispatches, last-activity relative time)
  - Dependency edges (depends-on / depended-by repo name lists)

  The component belongs to the canonical `:workflow_progress_and_status` family.
  Host applications own map-surface placement, concrete routes, and runtime event
  transport.
  """

  use LiveUi.Component,
    family: :workflow_progress_and_status,
    name: :repo_progress_card,
    events: [:click]

  LiveUi.Component.common_attrs()
  attr(:name, :string, required: true)
  attr(:progress_pct, :float, default: 0.0)
  attr(:active_count, :integer, default: 0)
  attr(:blocked_count, :integer, default: 0)
  attr(:path, :string, default: nil)
  attr(:last_activity_label, :string, default: nil)
  attr(:depends_on, :list, default: [])
  attr(:depended_by, :list, default: [])
  attr(:selected?, :boolean, default: false)
  attr(:focus_intent, :string, default: "focus_repo")
  attr(:open_action, :map, default: nil)

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(:progress_pct_int, trunc((assigns.progress_pct || 0.0) * 100))
      |> assign(:show_open_action, open_action_visible?(assigns.open_action, assigns.selected?))

    ~H"""
    <article
      id={@id}
      data-live-ui-widget="repo-progress-card"
      data-repo-card={@name}
      data-selected={to_string(@selected?)}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={[
        "live-ui-repo-progress-card",
        @selected? && "live-ui-repo-progress-card--selected",
        @class
      ]}
      {@rest}
    >
      <header class="live-ui-repo-progress-card__header">
        <button
          type="button"
          class="live-ui-repo-progress-card__focus"
          aria-pressed={to_string(@selected?)}
          phx-click="live_ui_interaction"
          phx-value-intent={@focus_intent}
          phx-value-element-id={@name}
          phx-value-value={@name}
        >
          <span class="live-ui-repo-progress-card__title"><%= @name %></span>
          <%= if @path do %>
            <span class="live-ui-repo-progress-card__path"><%= @path %></span>
          <% end %>
        </button>
        <%= if @show_open_action && @open_action do %>
          <button
            type="button"
            class="live-ui-repo-progress-card__open-action"
            phx-click="live_ui_interaction"
            phx-value-intent={@open_action[:intent] || @open_action["intent"]}
            phx-value-element-id={@name}
            phx-value-value={@name}
          >
            <%= @open_action[:label] || @open_action["label"] %>
          </button>
        <% end %>
      </header>

      <div
        class="live-ui-repo-progress-card__progress-track"
        role="progressbar"
        aria-valuenow={@progress_pct_int}
        aria-valuemin="0"
        aria-valuemax="100"
        aria-label={"#{@name} progress: #{@progress_pct_int}%"}
      >
        <div
          class="live-ui-repo-progress-card__progress-fill"
          style={"width: #{@progress_pct_int}%"}
        >
        </div>
      </div>

      <div class="live-ui-repo-progress-card__stats">
        <span class="live-ui-repo-progress-card__stat-chip">
          <%= @active_count %> active
        </span>
        <span
          class="live-ui-repo-progress-card__stat-chip"
          data-loud={to_string(@blocked_count > 0)}
          aria-label={blocked_aria_label(@blocked_count)}
        >
          <%= @blocked_count %> blocked
        </span>
        <%= if @last_activity_label do %>
          <span class="live-ui-repo-progress-card__stat-chip">
            <%= @last_activity_label %>
          </span>
        <% end %>
      </div>

      <%= if @depends_on != [] do %>
        <div class="live-ui-repo-progress-card__deps live-ui-repo-progress-card__deps--depends-on">
          depends on: <%= Enum.join(@depends_on, ", ") %>
        </div>
      <% end %>
      <%= if @depended_by != [] do %>
        <div class="live-ui-repo-progress-card__deps live-ui-repo-progress-card__deps--depended-by">
          depended by: <%= Enum.join(@depended_by, ", ") %>
        </div>
      <% end %>
    </article>
    """
  end

  defp open_action_visible?(nil, _selected?), do: false

  defp open_action_visible?(open_action, selected?) do
    visible_when = open_action[:visible_when] || open_action["visible_when"] || :always

    case visible_when do
      :always -> true
      :when_selected -> selected?
      :when_selected_and_has_children -> selected?
      _ -> true
    end
  end

  defp blocked_aria_label(0), do: "0 blocked"
  defp blocked_aria_label(count), do: "#{count} blocked, attention needed"
end
