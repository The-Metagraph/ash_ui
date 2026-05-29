defmodule LiveUi.Widgets.EscalationCard do
  @moduledoc """
  Native escalation card for a cross-team escalation raised by an MCP tool.

  The widget renders the canonical `:escalation_card` callout shape for
  `:escalation_raised` SessionEvents. Severity, evidence references, and
  operator routing actions are exposed; acknowledged state is stateless
  (state lives in the consumer LiveView).
  """

  use LiveUi.Component,
    family: :layer_shell_and_callout,
    name: :escalation_card,
    slots: [],
    events: [:acknowledge, :route_to_rail]

  LiveUi.Component.common_attrs()
  attr(:target_project_id, :string, required: true)
  attr(:severity, :atom, required: true)
  attr(:text, :string, required: true)
  attr(:related_finding_id, :string, default: nil)
  attr(:proposed_action, :string, default: nil)
  attr(:target_finding_id, :string, default: nil)
  attr(:target_severity, :atom, default: nil)
  attr(:originating_severity, :atom, default: nil)
  attr(:actor_handle, :string, default: nil)
  attr(:escalated_at, :string, default: nil)
  attr(:acknowledged?, :boolean, default: false)
  attr(:ack_attrs, :any, default: [])
  attr(:route_attrs, :any, default: [])

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(:card_id, assigns.id)
      |> assign(:severity_label, severity_label(assigns.severity))

    ~H"""
    <article
      id={@card_id}
      data-live-ui-widget="escalation-card"
      data-severity={@severity}
      data-acknowledged={if @acknowledged?, do: "true", else: "false"}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={escalation_card_class(@class, @severity)}
      role="alert"
      aria-labelledby={"#{@card_id}-title"}
      {@rest}
    >
      <header class="live-ui-escalation-card__header">
        <span class="live-ui-escalation-card__severity-badge" role="status">
          <%= @severity_label %>
        </span>
        <h3 id={"#{@card_id}-title"} class="live-ui-escalation-card__title">Escalation</h3>
        <span :if={@actor_handle} class="live-ui-escalation-card__actor">
          <%= @actor_handle %>
        </span>
      </header>

      <p class="live-ui-escalation-card__text"><%= @text %></p>

      <dl :if={@target_project_id || @proposed_action} class="live-ui-escalation-card__meta">
        <dt :if={@target_project_id}>Target project</dt>
        <dd :if={@target_project_id}><%= @target_project_id %></dd>
        <dt :if={@proposed_action}>Proposed action</dt>
        <dd :if={@proposed_action}><%= @proposed_action %></dd>
      </dl>

      <footer :if={not @acknowledged?} class="live-ui-escalation-card__actions">
        <button
          type="button"
          class="live-ui-escalation-card__acknowledge"
          aria-label={"Acknowledge #{@severity} escalation"}
          {action_attrs(@ack_attrs, "acknowledge")}
        >
          Acknowledge
        </button>
        <button
          type="button"
          class="live-ui-escalation-card__route-to-rail"
          aria-label={"Route #{@severity} escalation to rail"}
          {action_attrs(@route_attrs, "route_to_rail")}
        >
          Route to rail
        </button>
      </footer>

      <p
        :if={@acknowledged?}
        class="live-ui-escalation-card__acknowledged"
        role="status"
      >
        Acknowledged
      </p>
    </article>
    """
  end

  defp escalation_card_class(extra_class, severity) do
    [
      "live-ui-escalation-card",
      "live-ui-escalation-card--#{severity}",
      extra_class
    ]
  end

  defp severity_label(severity) when is_atom(severity),
    do: severity |> Atom.to_string() |> String.upcase()

  defp severity_label(severity) when is_binary(severity), do: String.upcase(severity)
  defp severity_label(_severity), do: ""

  defp action_attrs(attrs, fallback_event) when attrs in [nil, [], %{}],
    do: %{:"phx-click" => fallback_event}

  defp action_attrs(attrs, _fallback_event), do: attrs
end
