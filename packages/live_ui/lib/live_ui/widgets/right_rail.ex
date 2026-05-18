defmodule LiveUi.Widgets.RightRail do
  @moduledoc """
  Native renderer for the canonical `:right_rail` layer shell component.

  The widget consumes canonical `attributes.rail` data from `UnifiedIUR` and
  renderer-supplied interaction attributes. It does not own route, path, or
  framework-specific navigation fields.
  """

  use LiveUi.Component,
    family: :layer_shell_and_callout,
    name: :right_rail,
    slots: [:panel],
    events: [:selection, :change]

  LiveUi.Component.common_attrs()

  attr(:side, :atom, default: :right)
  attr(:panels, :list, required: true)
  attr(:active_panel, :any, required: true)
  attr(:collapsed?, :boolean, default: false)
  attr(:collapsible?, :boolean, default: true)
  attr(:density, :any, default: nil)
  attr(:width, :any, default: nil)
  attr(:panel_attrs, :map, default: %{})
  attr(:collapse_attrs, :map, default: %{})

  slot :panel do
    attr(:id, :any)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <aside
      id={@id}
      class={["live-ui-right-rail", @class]}
      data-live-ui-widget="right-rail"
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      data-live-ui-rail-side={@side}
      data-live-ui-rail-active-panel={@active_panel}
      data-live-ui-rail-collapsed={@collapsed?}
      data-live-ui-rail-collapsible={@collapsible?}
      data-live-ui-rail-density={@density}
      data-live-ui-rail-width={@width}
      {@rest}
    >
      <div class="live-ui-right-rail__tabs" role="tablist" aria-orientation="vertical">
        <button
          :for={panel <- @panels}
          id={panel_tab_id(@id, panel)}
          type="button"
          role="tab"
          aria-selected={panel_selected?(panel, @active_panel)}
          aria-controls={panel_body_id(@id, panel)}
          disabled={panel_disabled?(panel)}
          class={["live-ui-right-rail__tab", panel_active?(panel, @active_panel) && "is-active"]}
          data-live-ui-rail-panel={panel_id(panel)}
          {Map.get(@panel_attrs, panel_key(panel), %{})}
        >
          <span class="live-ui-right-rail__tab-label">{panel_label(panel)}</span>
          <span :if={panel_badge(panel)} class="live-ui-right-rail__tab-badge">{panel_badge(panel)}</span>
        </button>

        <button
          :if={@collapsible?}
          type="button"
          class="live-ui-right-rail__collapse"
          aria-expanded={expanded_value(@collapsed?)}
          data-live-ui-rail-collapse
          {@collapse_attrs}
        >
          {collapse_label(@collapsed?)}
        </button>
      </div>

      <section
        :for={panel <- active_panels(@panels, @active_panel)}
        id={panel_body_id(@id, panel)}
        role="tabpanel"
        aria-labelledby={panel_tab_id(@id, panel)}
        class="live-ui-right-rail__panel"
        data-live-ui-rail-panel-body={panel_id(panel)}
      >
        <%= unless @collapsed? do %>
          <%= if panel_slot_present?(@panel, panel_id(panel)) do %>
            <%= for slot <- matching_panel_slots(@panel, panel_id(panel)) do %>
              <%= render_slot(slot) %>
            <% end %>
          <% else %>
            {panel_empty_state(panel)}
          <% end %>
        <% end %>
      </section>
    </aside>
    """
  end

  defp active_panels(panels, active_panel) do
    panels
    |> List.wrap()
    |> Enum.filter(&panel_active?(&1, active_panel))
  end

  defp panel_id(panel), do: fetch_panel(panel, :id)
  defp panel_label(panel), do: fetch_panel(panel, :label, panel_id(panel))
  defp panel_badge(panel), do: fetch_panel(panel, :badge)
  defp panel_empty_state(panel), do: fetch_panel(panel, :empty_state, "")

  defp panel_disabled?(panel) do
    fetch_panel(panel, :disabled?) || fetch_panel(panel, :disabled) || false
  end

  defp panel_active?(panel, active_panel) do
    to_string(panel_id(panel)) == to_string(active_panel)
  end

  defp panel_selected?(panel, active_panel) do
    if panel_active?(panel, active_panel), do: "true", else: "false"
  end

  defp panel_key(panel), do: panel_id(panel) |> normalize_key()

  defp panel_tab_id(id, panel), do: "#{id}-#{panel_key(panel)}-tab"
  defp panel_body_id(id, panel), do: "#{id}-#{panel_key(panel)}-panel"

  defp panel_slot_present?(slots, panel_id) do
    Enum.any?(slots, &panel_slot?(&1, panel_id))
  end

  defp matching_panel_slots(slots, panel_id) do
    Enum.filter(slots, &panel_slot?(&1, panel_id))
  end

  defp panel_slot?(slot, panel_id) do
    to_string(slot[:id]) == to_string(panel_id)
  end

  defp expanded_value(true), do: "false"
  defp expanded_value(false), do: "true"

  defp collapse_label(true), do: "Expand"
  defp collapse_label(false), do: "Collapse"

  defp fetch_panel(panel, key, default \\ nil)

  defp fetch_panel(panel, key, default) when is_map(panel) do
    Map.get(panel, key, Map.get(panel, to_string(key), default))
  end

  defp fetch_panel(panel, key, default) when is_list(panel), do: Keyword.get(panel, key, default)
  defp fetch_panel(_panel, _key, default), do: default

  defp normalize_key(nil), do: "panel"

  defp normalize_key(value) do
    value
    |> to_string()
    |> String.replace(~r/[^a-zA-Z0-9_-]+/, "-")
  end
end
