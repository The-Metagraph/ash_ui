defmodule LiveUi.Widgets.DocRightRail do
  @moduledoc """
  Baseline native doc_right_rail widget.

  Persistent right-side companion panel for Doc mode with a three-tab strip
  (Agents / Sources / History) and slotted body content per tab. The panel
  owns the chrome (aside semantics, width variant, collapsed state, tab strip)
  while delegating body content to caller-supplied inner_block slots.

  The tab strip uses bespoke rendering (Option B per spec) for v1 clarity.
  Option A — composing canonical :tabs IUR as a child — is architecturally
  preferred once the :tabs count badge extension lands (unified_ui#188).

  ## Open design questions (DRAFT, Pascal-review REQUIRED)
  - Family assignment: `:layer_shell_and_callout` vs proposed `:content_panels`?
  - Width / responsive behaviour: concrete px values per :width_variant?
  - Collapse event: part of :on_tab_change payload vs separate event?
  - Empty state per tab: caller-supplied or widget-supplied with per-tab label?
  - Sticky position CSS: `height: calc(100vh - header)` implementation detail?
  - Wave 4b slot placeholder contract: mandated empty-state shape or caller choice?
  """

  use LiveUi.Component, family: :navigation, name: :doc_right_rail, events: [:click]

  LiveUi.Component.common_attrs()
  attr(:doc_id, :string, required: true)
  attr(:active_tab, :atom, default: :sources)
  attr(:tabs, :list, default: [])
  attr(:collapsed?, :boolean, default: false)
  attr(:width_variant, :atom, default: :standard)
  attr(:position, :atom, default: :fixed_right)
  attr(:on_tab_change, :string, default: "")
  attr(:event_target, :any, default: nil)

  slot(:agents_body)
  slot(:sources_body)
  slot(:history_body)

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign_new(:tabs, fn -> default_tabs() end)

    ~H"""
    <aside
      id={@id}
      data-live-ui-widget="doc-right-rail"
      data-doc-id={@doc_id}
      data-active-tab={Atom.to_string(@active_tab)}
      data-collapsed={Atom.to_string(@collapsed?)}
      data-width-variant={Atom.to_string(@width_variant)}
      data-position={Atom.to_string(@position)}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={[
        "live-ui-doc-right-rail",
        @collapsed? && "live-ui-doc-right-rail--collapsed",
        "live-ui-doc-right-rail--#{@width_variant}",
        @class
      ]}
      aria-label="Document companion panel"
      aria-expanded={Atom.to_string(!@collapsed?)}
      {@rest}
    >
      <nav
        class="live-ui-doc-right-rail__tab-strip"
        aria-label="Panel tabs"
        role="tablist"
      >
        <%= for tab <- effective_tabs(@tabs) do %>
          <button
            type="button"
            role="tab"
            class={[
              "live-ui-doc-right-rail__tab",
              tab.kind == @active_tab && "live-ui-doc-right-rail__tab--active"
            ]}
            data-tab={Atom.to_string(tab.kind)}
            aria-selected={Atom.to_string(tab.kind == @active_tab)}
            aria-controls={"doc-right-rail-panel-#{@doc_id}-#{tab.kind}"}
            aria-label={tab_aria_label(tab, @collapsed?)}
            phx-click={@on_tab_change}
            phx-value-tab={Atom.to_string(tab.kind)}
            phx-target={@event_target}
          >
            <span class="live-ui-doc-right-rail__tab-label"><%= tab.label %></span>
            <%= if tab.count do %>
              <span
                class="live-ui-doc-right-rail__tab-count"
                aria-label={", #{tab.count} items"}
              >
                <%= tab.count %>
              </span>
            <% end %>
          </button>
        <% end %>
      </nav>

      <div
        id={"doc-right-rail-panel-#{@doc_id}-#{@active_tab}"}
        class="live-ui-doc-right-rail__body"
        role="tabpanel"
        aria-label={active_tab_label(effective_tabs(@tabs), @active_tab)}
      >
        <%= case @active_tab do %>
          <% :agents -> %>
            <%= if @agents_body != [] do %>
              <%= render_slot(@agents_body, %{doc_id: @doc_id}) %>
            <% else %>
              <div class="live-ui-doc-right-rail__empty-state">
                Agent task cards available in Wave 4b.
              </div>
            <% end %>
          <% :sources -> %>
            <%= if @sources_body != [] do %>
              <%= render_slot(@sources_body, %{doc_id: @doc_id}) %>
            <% else %>
              <div class="live-ui-doc-right-rail__empty-state">No sources yet.</div>
            <% end %>
          <% :history -> %>
            <%= if @history_body != [] do %>
              <%= render_slot(@history_body, %{doc_id: @doc_id}) %>
            <% else %>
              <div class="live-ui-doc-right-rail__empty-state">No history yet.</div>
            <% end %>
          <% _ -> %>
            <div class="live-ui-doc-right-rail__empty-state">Select a tab.</div>
        <% end %>
      </div>
    </aside>
    """
  end

  defp default_tabs do
    [
      %{kind: :agents, label: "Agents", count: nil},
      %{kind: :sources, label: "Sources", count: nil},
      %{kind: :history, label: "History", count: nil}
    ]
  end

  defp effective_tabs([]), do: default_tabs()
  defp effective_tabs(tabs), do: tabs

  defp tab_aria_label(%{label: label, count: count}, collapsed?) do
    base = if collapsed?, do: "#{label} (expand)", else: label
    if count, do: "#{base}, #{count} items", else: base
  end

  defp active_tab_label(tabs, active_tab) do
    case Enum.find(tabs, fn t -> t.kind == active_tab end) do
      %{label: label} -> "#{label} panel"
      nil -> "Panel"
    end
  end
end
