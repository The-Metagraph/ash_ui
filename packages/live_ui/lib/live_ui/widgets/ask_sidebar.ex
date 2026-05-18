defmodule LiveUi.Widgets.AskSidebar do
  @moduledoc """
  Native Ask-mode sidebar shell widget.

  The Ask-mode sidebar replaces `:sidebar_shell` while the operator is in Ask
  mode. It provides two persistent navigation rails:

  - **Recent** — chronological query history, capped at 10, with relative
    timestamps and a running-status indicator.
  - **Saved** — pinned or named queries with a ★ glyph, optional cadence label,
    and a "+ new" action.

  A **Map jump** affordance at the bottom lets the operator switch back to Map
  mode without losing the Ask surface. It carries an optional blocker-count badge.

  The widget is a pure display surface — all state is host-managed. No internal
  state; all transitions are driven by parent assigns.

  ## Required attributes

    * `:sidebar_id` — root identity string; used as `data-sidebar-id` and as the
      suffix for scoped ARIA heading ids.
    * `:on_map_jump_event` — canonical Interaction intent string for the Map jump
      button (emitted as `data-live-ui-intent`).

  ## Optional attributes

    * `:recent_items` — list of `%{id, query, last_run_at, status, on_open_event}`
      maps. Renderer caps display at 10.
    * `:saved_items` — list of `%{id, title, query, on_open_event}` maps. Optional
      per-item keys: `:cadence`, `:last_run_at`.
    * `:active_item_id` — id of the currently-open item; row gets `aria-current="true"`.
    * `:on_new_saved_event` — intent string for the "+ new" save button in the Saved rail.
    * `:on_see_all_event` — intent string for "see all ▸" (visible when `recent_items`
      exceeds 6).
    * `:empty_recent_label` — message when Recent rail is empty
      (default `"No recent queries"`).
    * `:empty_saved_label` — message when Saved rail is empty
      (default `"No saved queries yet"`).
    * `:blocker_count` — non-negative integer badge on the Map jump button; `0`
      hides the badge (default `0`).

  ## Selector / hook contract

  Root: `data-live-ui-widget="ask-sidebar"` + `data-sidebar-id="{id}"`.
  Recent rail: `.live-ui-ask-sidebar__section[aria-labelledby="ask-recent-h-{id}"]`.
  Saved rail: `.live-ui-ask-sidebar__section[aria-labelledby="ask-saved-h-{id}"]`.
  Active item: `.live-ui-ask-sidebar__item--active` + `aria-current="true"`.
  Running status: `.live-ui-ask-sidebar__status-running`.
  Map jump: `.live-ui-ask-sidebar__map-jump-btn`.
  Blocker badge: `.live-ui-ask-sidebar__blocker-badge`.

  ## ARIA

  - Root `<aside aria-label="Ask sidebar">` — distinguishes from the standard sidebar.
  - Recent and Saved `<section aria-labelledby="...">` with scoped heading ids.
  - Active row: `aria-current="true"`.
  - Running-status indicator: `aria-label="running"`.
  - Map jump button: `aria-label="Switch to Map mode"`.
  - Blocker badge: `aria-label="{N} blockers"`.

  ## Open questions for Pascal (Wave 3.7-B)

  1. **Shell-swap vs section composition vs ariston-local?** — Top design call.
     Current draft assumes option (a): new canonical widget swapping for `:sidebar_shell`.
  2. **Mode-switch mechanism**: IUR re-render vs LiveView hot-swap?
  3. **"See all" overlay**: internal vs event-to-host (current draft) vs deferred?
  4. **Saved rail filter** at 20+ items: renderer threshold, host-supplied value, or v2?
  5. **Map jump placement**: bottom of scroll vs sticky footer?
  6. **Width/position parity with `:sidebar_shell`**: share CSS tokens or distinct?
  7. **Empty state for first-time user**: combined onboarding vs per-rail labels (current draft).
  8. **Bottom identity bar** (`sb-bottom`): part of widget contract or host-injected?
  """

  use LiveUi.Component,
    family: :overlay,
    name: :ask_sidebar,
    events: [:click]

  LiveUi.Component.common_attrs()
  attr(:sidebar_id, :string, required: true)
  attr(:on_map_jump_event, :string, required: true)
  attr(:recent_items, :list, default: [])
  attr(:saved_items, :list, default: [])
  attr(:active_item_id, :string, default: nil)
  attr(:on_new_saved_event, :string, default: nil)
  attr(:on_see_all_event, :string, default: nil)
  attr(:empty_recent_label, :string, default: "No recent queries")
  attr(:empty_saved_label, :string, default: "No saved queries yet")
  attr(:blocker_count, :integer, default: 0)

  @impl true
  def render(assigns) do
    assigns =
      assign(assigns,
        recent_display: Enum.take(assigns.recent_items, 10),
        show_see_all: assigns.on_see_all_event != nil and length(assigns.recent_items) > 6
      )

    ~H"""
    <aside
      id={@id}
      data-live-ui-widget="ask-sidebar"
      data-sidebar-id={@sidebar_id}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      aria-label="Ask sidebar"
      class={["live-ui-ask-sidebar", @class]}
      {@rest}
    >
      <div class="live-ui-ask-sidebar__scroll">

        <%!-- Recent rail --%>
        <section
          class="live-ui-ask-sidebar__section"
          aria-labelledby={"ask-recent-h-#{@sidebar_id}"}
        >
          <div class="live-ui-ask-sidebar__section-header">
            <span
              id={"ask-recent-h-#{@sidebar_id}"}
              class="live-ui-ask-sidebar__section-label"
            >
              Recent
            </span>
            <span class="live-ui-ask-sidebar__section-cap">
              last <%= min(length(@recent_items), 10) %>
            </span>
            <%= if @show_see_all do %>
              <button
                type="button"
                class="live-ui-ask-sidebar__see-all"
                data-live-ui-intent={@on_see_all_event}
                data-sidebar-id={@sidebar_id}
              >
                see all &#x25B8;
              </button>
            <% end %>
          </div>

          <div class="live-ui-ask-sidebar__rail">
            <%= if Enum.empty?(@recent_items) do %>
              <p class="live-ui-ask-sidebar__empty"><%= @empty_recent_label %></p>
            <% else %>
              <%= for item <- @recent_display do %>
                <button
                  type="button"
                  class={[
                    "live-ui-ask-sidebar__item",
                    "live-ui-ask-sidebar__item--recent",
                    item_active_class(@active_item_id, item_id(item))
                  ]}
                  aria-current={aria_current(@active_item_id, item_id(item))}
                  title={item_field(item, :query)}
                  data-live-ui-intent={item_field(item, :on_open_event)}
                  data-live-ui-value={item_id(item)}
                  data-item-id={item_id(item)}
                >
                  <span class="live-ui-ask-sidebar__item-glyph" aria-hidden="true">&#x1F553;</span>
                  <span class="live-ui-ask-sidebar__item-label"><%= item_field(item, :query) %></span>
                  <span class="live-ui-ask-sidebar__item-meta">
                    <%= relative_time(item_field(item, :last_run_at)) %>
                    <%= if item_status_running?(item) do %>
                      <span class="live-ui-ask-sidebar__status-running" aria-label="running"></span>
                    <% end %>
                  </span>
                </button>
              <% end %>
            <% end %>
          </div>
        </section>

        <%!-- Saved rail --%>
        <section
          class="live-ui-ask-sidebar__section"
          aria-labelledby={"ask-saved-h-#{@sidebar_id}"}
        >
          <div class="live-ui-ask-sidebar__section-header">
            <span
              id={"ask-saved-h-#{@sidebar_id}"}
              class="live-ui-ask-sidebar__section-label"
            >
              Saved
            </span>
            <span class="live-ui-ask-sidebar__section-cap"><%= length(@saved_items) %></span>
            <%= if @on_new_saved_event do %>
              <button
                type="button"
                class="live-ui-ask-sidebar__new-saved"
                title="Save current query"
                data-live-ui-intent={@on_new_saved_event}
                data-sidebar-id={@sidebar_id}
              >
                + new
              </button>
            <% end %>
          </div>

          <div class="live-ui-ask-sidebar__rail">
            <%= if Enum.empty?(@saved_items) do %>
              <p class="live-ui-ask-sidebar__empty"><%= @empty_saved_label %></p>
            <% else %>
              <%= for item <- @saved_items do %>
                <button
                  type="button"
                  class={[
                    "live-ui-ask-sidebar__item",
                    "live-ui-ask-sidebar__item--saved",
                    item_active_class(@active_item_id, item_id(item))
                  ]}
                  aria-current={aria_current(@active_item_id, item_id(item))}
                  title={item_field(item, :title)}
                  data-live-ui-intent={item_field(item, :on_open_event)}
                  data-live-ui-value={item_id(item)}
                  data-item-id={item_id(item)}
                >
                  <span
                    class="live-ui-ask-sidebar__item-glyph live-ui-ask-sidebar__item-glyph--star"
                    aria-hidden="true"
                  >
                    &#x2605;
                  </span>
                  <span class="live-ui-ask-sidebar__item-label"><%= item_field(item, :title) %></span>
                  <span class="live-ui-ask-sidebar__item-meta">
                    <%= saved_item_meta(item) %>
                  </span>
                </button>
              <% end %>
            <% end %>
          </div>
        </section>

        <%!-- Map jump affordance --%>
        <div class="live-ui-ask-sidebar__map-jump">
          <button
            type="button"
            class="live-ui-ask-sidebar__map-jump-btn"
            aria-label="Switch to Map mode"
            title="Map (&#x2318;2)"
            data-live-ui-intent={@on_map_jump_event}
            data-live-ui-value="map"
            data-sidebar-id={@sidebar_id}
          >
            <span class="live-ui-ask-sidebar__map-jump-glyph" aria-hidden="true">&#x25BE;</span>
            <span class="live-ui-ask-sidebar__map-jump-label">Map</span>
            <%= if @blocker_count > 0 do %>
              <span
                class="live-ui-ask-sidebar__blocker-badge"
                aria-label={"#{@blocker_count} blockers"}
              >
                <%= @blocker_count %>
              </span>
            <% end %>
          </button>
        </div>

      </div>
    </aside>
    """
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp item_id(item) when is_map(item) do
    Map.get(item, :id) || Map.get(item, "id") || ""
  end

  defp item_field(item, key) when is_map(item) do
    Map.get(item, key) || Map.get(item, Atom.to_string(key))
  end

  defp item_active_class(nil, _item_id), do: nil

  defp item_active_class(active_id, item_id) when active_id == item_id,
    do: "live-ui-ask-sidebar__item--active"

  defp item_active_class(_active_id, _item_id), do: nil

  defp aria_current(nil, _item_id), do: "false"
  defp aria_current(active_id, item_id) when active_id == item_id, do: "true"
  defp aria_current(_active_id, _item_id), do: "false"

  defp item_status_running?(item) do
    item_field(item, :status) == :running
  end

  defp saved_item_meta(item) do
    cadence = item_field(item, :cadence)
    last_run_at = item_field(item, :last_run_at)

    cond do
      is_binary(cadence) and cadence != "" -> cadence
      last_run_at != nil -> relative_time(last_run_at)
      true -> ""
    end
  end

  defp relative_time(%DateTime{} = dt) do
    now = DateTime.utc_now()
    diff_seconds = DateTime.diff(now, dt, :second)

    cond do
      diff_seconds < 60 -> "just now"
      diff_seconds < 3600 -> "#{div(diff_seconds, 60)}m ago"
      diff_seconds < 86_400 -> "#{div(diff_seconds, 3600)}h ago"
      diff_seconds < 604_800 -> "#{div(diff_seconds, 86_400)}d ago"
      true -> "#{div(diff_seconds, 604_800)}w ago"
    end
  end

  defp relative_time(_other), do: ""
end
