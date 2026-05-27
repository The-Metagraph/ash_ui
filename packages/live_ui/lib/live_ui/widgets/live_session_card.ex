defmodule LiveUi.Widgets.LiveSessionCard do
  @moduledoc """
  Native live-session card widget.

  Renders one actively running assistant session as a compact workflow progress
  and status card with prop-sourced meters, live assistant text, recent events,
  and Pin/Interrupt controls.
  """

  use LiveUi.Component,
    family: :workflow_progress_and_status,
    name: :live_session_card,
    slots: [],
    events: [:pin_toggled, :interrupted, :expanded_recent]

  LiveUi.Component.common_attrs()
  attr(:session_id, :string, required: true)
  attr(:actor_handle, :string, required: true)
  attr(:status, :atom, required: true)
  attr(:status_version, :integer, required: true)
  attr(:tools_count, :integer, required: true)
  attr(:edits_count, :integer, required: true)
  attr(:tokens_consumed, :integer, required: true)
  attr(:started_at, :any, required: true)
  attr(:current_step, :string, default: nil)
  attr(:current_task_title, :string, default: nil)
  attr(:now_streaming, :string, default: nil)
  attr(:recent_events, :list, default: [])
  attr(:pinned?, :boolean, default: false)
  attr(:pin_attrs, :any, default: [])
  attr(:interrupt_attrs, :any, default: [])
  attr(:recent_attrs, :any, default: [])

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(:recent_events, recent_events(assigns.recent_events))
      |> assign(:status_label, status_label(assigns.status))
      |> assign(:duration_label, duration_label(assigns.started_at))
      |> assign(:started_at_iso, timestamp_iso8601(assigns.started_at))

    ~H"""
    <article
      id={@id}
      data-live-ui-widget="live-session-card"
      data-session-id={@session_id}
      data-status-version={@status_version}
      data-pinned={if @pinned?, do: "true", else: "false"}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={[
        "live-ui-live-session-card",
        "live-ui-live-session-card--running",
        @pinned? && "is-pinned",
        @class
      ]}
      {@rest}
    >
      <header class="live-ui-live-session-card__header">
        <span class="live-ui-live-session-card__avatar" aria-hidden="true">
          <%= avatar_initials(@actor_handle) %>
        </span>
        <div class="live-ui-live-session-card__identity">
          <h3 class="live-ui-live-session-card__actor"><%= @actor_handle %></h3>
          <%= if present?(@current_task_title) do %>
            <p class="live-ui-live-session-card__task"><%= @current_task_title %></p>
          <% else %>
            <%= if present?(@current_step) do %>
              <p class="live-ui-live-session-card__task"><%= @current_step %></p>
            <% end %>
          <% end %>
        </div>
        <span class="live-ui-live-session-card__status-badge" role="status">
          <%= @status_label %>
        </span>
        <time class="live-ui-live-session-card__duration" datetime={@started_at_iso}>
          <%= @duration_label %>
        </time>
      </header>

      <div class="live-ui-live-session-card__meters">
        <div class="live-ui-live-session-card__meter" data-meter="tools">
          <span class="live-ui-live-session-card__meter-value"><%= @tools_count %></span>
          <span class="live-ui-live-session-card__meter-label">tools</span>
        </div>
        <div class="live-ui-live-session-card__meter" data-meter="edits">
          <span class="live-ui-live-session-card__meter-value"><%= @edits_count %></span>
          <span class="live-ui-live-session-card__meter-label">edits</span>
        </div>
        <div class="live-ui-live-session-card__meter" data-meter="tokens">
          <span class="live-ui-live-session-card__meter-value"><%= @tokens_consumed %></span>
          <span class="live-ui-live-session-card__meter-label">tokens</span>
        </div>
      </div>

      <div
        :if={present?(@now_streaming)}
        class="live-ui-live-session-card__now-streaming"
        aria-live="polite"
        aria-atomic="true"
      >
        <span class="live-ui-live-session-card__live-indicator" aria-hidden="true">LIVE</span>
        <span class="live-ui-live-session-card__now-streaming-text"><%= @now_streaming %></span>
      </div>

      <ol
        class="live-ui-live-session-card__recent"
        aria-label={"Recent activity for #{@actor_handle}"}
        {recent_list_attrs(@recent_attrs)}
      >
        <li :for={event <- @recent_events} class="live-ui-live-session-card__recent-item">
          <span class="live-ui-live-session-card__recent-kind">
            <%= event_kind(event) %>
          </span>
          <span class="live-ui-live-session-card__recent-body">
            <%= event_body(event) %>
          </span>
        </li>
      </ol>

      <footer class="live-ui-live-session-card__actions">
        <button
          type="button"
          class="live-ui-live-session-card__pin"
          aria-label={pin_aria_label(@pinned?, @actor_handle)}
          aria-pressed={to_string(@pinned?)}
          {pin_attrs(@pin_attrs)}
        >
          <%= pin_label(@pinned?) %>
        </button>
        <button
          type="button"
          class="live-ui-live-session-card__interrupt"
          aria-label={"Interrupt #{@actor_handle} running session"}
          {interrupt_attrs(@interrupt_attrs)}
        >
          Interrupt
        </button>
      </footer>
    </article>
    """
  end

  defp recent_events(events) when is_list(events), do: Enum.take(events, 5)
  defp recent_events(_events), do: []

  defp avatar_initials(handle) when is_binary(handle) do
    handle
    |> String.trim_leading("@")
    |> String.trim()
    |> String.first()
    |> case do
      nil -> "?"
      "" -> "?"
      first -> String.upcase(first)
    end
  end

  defp avatar_initials(_handle), do: "?"

  defp status_label(status) do
    status
    |> to_string()
    |> String.replace("_", " ")
    |> String.upcase()
  end

  defp timestamp_iso8601(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp timestamp_iso8601(%NaiveDateTime{} = ndt), do: NaiveDateTime.to_iso8601(ndt)
  defp timestamp_iso8601(value) when is_binary(value), do: value
  defp timestamp_iso8601(_value), do: nil

  defp duration_label(%DateTime{} = started_at) do
    diff_seconds = max(DateTime.diff(DateTime.utc_now(), started_at, :second), 0)

    cond do
      diff_seconds < 60 -> "#{diff_seconds}s"
      diff_seconds < 3_600 -> "#{div(diff_seconds, 60)}m"
      true -> "#{div(diff_seconds, 3_600)}h"
    end
  end

  defp duration_label(_started_at), do: "running"

  defp event_kind(event) do
    event
    |> event_value(:kind, "")
    |> to_string()
    |> String.replace("_", " ")
  end

  defp event_body(event), do: event_value(event, :body, event_value(event, :body_fragment, ""))

  defp event_value(event, key, default) when is_map(event) do
    Map.get(event, key, Map.get(event, to_string(key), default))
  end

  defp event_value(_event, _key, default), do: default

  defp pin_label(true), do: "Pinned"
  defp pin_label(false), do: "Pin"

  defp pin_aria_label(true, actor_handle), do: "Unpin #{actor_handle} running session"
  defp pin_aria_label(false, actor_handle), do: "Pin #{actor_handle} running session"

  defp present?(value), do: is_binary(value) and String.trim(value) != ""

  defp pin_attrs(attrs) when attrs in [nil, [], %{}], do: %{:"phx-click" => "pin_toggled"}
  defp pin_attrs(attrs), do: attrs

  defp interrupt_attrs(attrs) when attrs in [nil, [], %{}], do: %{:"phx-click" => "interrupted"}
  defp interrupt_attrs(attrs), do: attrs

  defp recent_list_attrs(attrs) when attrs in [nil, [], %{}],
    do: %{:"phx-click" => "expanded_recent"}

  defp recent_list_attrs(attrs), do: attrs
end
