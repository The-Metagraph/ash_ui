defmodule LiveUi.Widgets.ToolCallCard do
  @moduledoc """
  Native tool-call card widget.

  Renders one assistant tool call in a conversation timeline with canonical
  expansion state and an optional paired result summary child.
  """

  use LiveUi.Component,
    family: :row_and_artifact,
    name: :tool_call_card,
    slots: [],
    events: [:expand_toggled]

  LiveUi.Component.common_attrs()
  attr(:tool_name, :string, required: true)
  attr(:tool_kind, :atom, required: true)
  attr(:target, :string, required: true)
  attr(:summary, :string, required: true)
  attr(:status, :atom, required: true)
  attr(:args, :map, default: %{})
  attr(:expanded?, :boolean, default: false)
  attr(:actor_handle, :string, default: nil)
  attr(:started_at, :any, default: nil)
  attr(:duration_ms, :integer, default: nil)
  attr(:approval_event_id, :string, default: nil)
  attr(:paired_result_event_id, :string, default: nil)
  attr(:tool_result_summary, :map, default: nil)
  attr(:expand_attrs, :any, default: [])

  @impl true
  def render(assigns) do
    ~H"""
    <article
      id={@id}
      data-live-ui-widget="tool-call-card"
      data-tool-kind={@tool_kind}
      data-status={@status}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={tool_call_card_class(@class, @status, @expanded?)}
      {@rest}
    >
      <header class="live-ui-tool-call-card__header">
        <span class="live-ui-tool-call-card__glyph" aria-hidden="true">
          <%= glyph_for_kind(@tool_kind) %>
        </span>
        <div class="live-ui-tool-call-card__identity">
          <h3 class="live-ui-tool-call-card__name"><%= @tool_name %></h3>
          <p class="live-ui-tool-call-card__target"><%= @target %></p>
        </div>
        <span class={["live-ui-tool-call-card__status-badge", status_class(@status)]}>
          <%= status_label(@status) %>
        </span>
      </header>

      <p class="live-ui-tool-call-card__summary"><%= @summary %></p>

      <div class="live-ui-tool-call-card__meta">
        <%= if @actor_handle do %>
          <span class="live-ui-tool-call-card__actor"><%= @actor_handle %></span>
        <% end %>
        <%= if @started_at do %>
          <time class="live-ui-tool-call-card__started-at" datetime={timestamp_iso8601(@started_at)}>
            <%= timestamp_label(@started_at) %>
          </time>
        <% end %>
        <%= if @duration_ms do %>
          <span class="live-ui-tool-call-card__duration"><%= duration_label(@duration_ms) %></span>
        <% end %>
      </div>

      <button
        type="button"
        class="live-ui-tool-call-card__expand-toggle"
        aria-label={"Toggle tool call #{@tool_name} details"}
        aria-expanded={if @expanded?, do: "true", else: "false"}
        aria-controls={"#{@id}-details"}
        {expand_button_attrs(@expand_attrs)}
      >
        Details
      </button>

      <%= if @expanded? do %>
        <section id={"#{@id}-details"} class="live-ui-tool-call-card__details">
          <h4 class="live-ui-tool-call-card__args-label">Args</h4>
          <pre class="live-ui-tool-call-card__args"><code><%= format_args(@args) %></code></pre>
        </section>
      <% end %>

      <%= if @tool_result_summary do %>
        <section class={["live-ui-tool-call-card__result", result_error?(@tool_result_summary) && "has-error"]}>
          <header class="live-ui-tool-call-card__result-header">
            <span class="live-ui-tool-call-card__result-event">
              <%= result_value(@tool_result_summary, :event_id) %>
            </span>
            <span class={["live-ui-tool-call-card__result-status", status_class(result_value(@tool_result_summary, :status))]}>
              <%= status_label(result_value(@tool_result_summary, :status)) %>
            </span>
          </header>
          <p class="live-ui-tool-call-card__result-output">
            <%= result_value(@tool_result_summary, :compact_output) %>
          </p>
          <%= if result_value(@tool_result_summary, :diff_summary) do %>
            <p class="live-ui-tool-call-card__result-diff">
              <%= result_value(@tool_result_summary, :diff_summary) %>
            </p>
          <% end %>
          <%= if result_error?(@tool_result_summary) do %>
            <p class="live-ui-tool-call-card__result-error">Error</p>
          <% end %>
        </section>
      <% end %>
    </article>
    """
  end

  defp tool_call_card_class(extra_class, status, expanded?) do
    [
      "live-ui-tool-call-card",
      "live-ui-tool-call-card--#{status}",
      expanded? && "is-expanded",
      extra_class
    ]
  end

  defp glyph_for_kind(:read), do: "R"
  defp glyph_for_kind(:edit), do: "E"
  defp glyph_for_kind(:write), do: "W"
  defp glyph_for_kind(:bash), do: "$"
  defp glyph_for_kind(:multiedit), do: "M"
  defp glyph_for_kind(:other), do: "?"
  defp glyph_for_kind(_other), do: "?"

  defp status_class(nil), do: nil
  defp status_class(status), do: "is-status-#{status}"

  defp status_label(nil), do: ""

  defp status_label(status) do
    status
    |> to_string()
    |> String.replace("_", " ")
  end

  defp timestamp_iso8601(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp timestamp_iso8601(%NaiveDateTime{} = ndt), do: NaiveDateTime.to_iso8601(ndt)
  defp timestamp_iso8601(value) when is_binary(value), do: value
  defp timestamp_iso8601(_other), do: nil

  defp timestamp_label(value) when is_binary(value), do: value
  defp timestamp_label(value), do: timestamp_iso8601(value) || ""

  defp duration_label(duration_ms) when is_integer(duration_ms) and duration_ms < 1_000 do
    "#{duration_ms}ms"
  end

  defp duration_label(duration_ms) when is_integer(duration_ms) do
    seconds = Float.round(duration_ms / 1_000, 1)
    "#{seconds}s"
  end

  defp duration_label(_duration_ms), do: ""

  defp format_args(args) when is_map(args) do
    inspect(args, pretty: true, limit: :infinity, printable_limit: :infinity)
  end

  defp format_args(_args), do: "%{}"

  defp expand_button_attrs(attrs) when attrs in [nil, [], %{}],
    do: %{:"phx-click" => "expand_toggled"}

  defp expand_button_attrs(attrs), do: attrs

  defp result_value(nil, _key), do: nil

  defp result_value(result, key) when is_map(result) do
    Map.get(result, key, Map.get(result, to_string(key)))
  end

  defp result_error?(result) do
    result_value(result, :error?) == true or result_value(result, :error) == true
  end
end
