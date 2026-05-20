defmodule LiveUi.Widgets.ComposerQueryPreview do
  @moduledoc """
  Native renderer for the canonical `:composer_query_preview` layer callout.

  The widget is a result-preview band mounted next to a composer. It receives
  canonical query preview attributes and renderer-supplied interaction attrs for
  dismiss, open, and save actions. It does not own query lifecycle, product mode,
  route, path, or Phoenix event names.
  """

  use LiveUi.Component,
    family: :layer_shell_and_callout,
    name: :composer_query_preview,
    events: [:close, :open, :command]

  LiveUi.Component.common_attrs()
  attr(:composer_id, :string, required: true)
  attr(:query, :string, required: true)
  attr(:preview_state, :atom, default: :empty)
  attr(:explanation, :string, default: nil)
  attr(:metrics, :map, default: nil)
  attr(:findings, :list, default: [])
  attr(:max_findings_shown, :integer, default: 2)
  attr(:error_message, :string, default: nil)
  attr(:loading_label, :string, default: "Searching")
  attr(:empty_label, :string, default: "No results for this query.")
  attr(:open_label, :string, default: "Open query")
  attr(:save_label, :string, default: "Save query")
  attr(:dismiss_attrs, :map, default: %{})
  attr(:open_attrs, :map, default: %{})
  attr(:save_attrs, :map, default: %{})

  @impl true
  def render(assigns) do
    ~H"""
    <section
      id={@id}
      data-live-ui-widget="composer-query-preview"
      data-composer-id={@composer_id}
      data-preview-state={@preview_state}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={["live-ui-composer-query-preview", @class]}
      role="region"
      aria-label={"Query preview: #{@query}"}
      aria-live="polite"
      {@rest}
    >
      <header class="live-ui-composer-query-preview__header">
        <span class="live-ui-composer-query-preview__query">
          <q><%= @query %></q>
        </span>
        <button
          type="button"
          class="live-ui-composer-query-preview__dismiss"
          aria-label="Dismiss query preview"
          {@dismiss_attrs}
        >
          x
        </button>
      </header>

      <%= case @preview_state do %>
        <% :loading -> %>
          <div class="live-ui-composer-query-preview__loading" aria-busy="true">
            <span><%= @loading_label %></span>
          </div>

        <% :ready -> %>
          <div :if={@explanation} class="live-ui-composer-query-preview__explanation">
            <%= @explanation %>
          </div>

          <div :if={@metrics} class="live-ui-composer-query-preview__metrics" aria-label="Query statistics">
            <span :if={metric_value(@metrics, :results_count)}>
              <strong><%= metric_value(@metrics, :results_count) %></strong> results
            </span>
            <span :if={metric_value(@metrics, :duration_ms)}>
              <%= duration_label(metric_value(@metrics, :duration_ms)) %>
            </span>
            <span :if={metric_value(@metrics, :sources_visited)}>
              <%= metric_value(@metrics, :sources_visited) %> sources
            </span>
          </div>

          <ul
            :if={@findings != []}
            class="live-ui-composer-query-preview__findings"
            aria-label="Query preview results"
          >
            <li
              :for={finding <- Enum.take(@findings, @max_findings_shown)}
              class="live-ui-composer-query-preview__finding"
              data-result-id={finding_value(finding, :id)}
            >
              <span
                class="live-ui-composer-query-preview__finding-rank"
                aria-label={"Result #{finding_value(finding, :n)}"}
              >
                #<%= finding_value(finding, :n) %>
              </span>
              <span class="live-ui-composer-query-preview__finding-snippet">
                <%= finding_value(finding, :snippet) %>
              </span>
              <span
                class="live-ui-composer-query-preview__finding-confidence"
                aria-label={"Confidence #{confidence_percent(finding_value(finding, :confidence))}%"}
              >
                <%= confidence_label(finding_value(finding, :confidence)) %>
              </span>
            </li>
          </ul>

          <div
            :if={length(@findings) > @max_findings_shown}
            class="live-ui-composer-query-preview__overflow"
            aria-label={"#{length(@findings) - @max_findings_shown} more results"}
          >
            +<%= length(@findings) - @max_findings_shown %> more
          </div>

        <% :empty -> %>
          <div class="live-ui-composer-query-preview__empty"><%= @empty_label %></div>

        <% :error -> %>
          <div class="live-ui-composer-query-preview__error" role="alert">
            <%= @error_message || "Query failed. Try again." %>
          </div>

        <% _ -> %>
      <% end %>

      <div :if={@preview_state != :loading} class="live-ui-composer-query-preview__actions">
        <button type="button" class="live-ui-composer-query-preview__open" {@open_attrs}>
          <%= @open_label %>
        </button>
        <button type="button" class="live-ui-composer-query-preview__save" {@save_attrs}>
          <%= @save_label %>
        </button>
      </div>
    </section>
    """
  end

  defp metric_value(nil, _key), do: nil

  defp metric_value(metrics, key) when is_map(metrics) do
    Map.get(metrics, key, Map.get(metrics, to_string(key)))
  end

  defp metric_value(metrics, key) when is_list(metrics), do: Keyword.get(metrics, key)
  defp metric_value(_metrics, _key), do: nil

  defp finding_value(finding, key) when is_map(finding) do
    Map.get(finding, key, Map.get(finding, to_string(key)))
  end

  defp finding_value(finding, key) when is_list(finding), do: Keyword.get(finding, key)
  defp finding_value(_finding, _key), do: nil

  defp duration_label(value) when is_integer(value) or is_float(value) do
    seconds = value / 1000
    :erlang.float_to_binary(seconds, decimals: 2) <> "s"
  end

  defp duration_label(value), do: to_string(value)

  defp confidence_percent(value) when is_integer(value) or is_float(value) do
    value
    |> max(0)
    |> min(1)
    |> Kernel.*(100)
    |> round()
  end

  defp confidence_percent(_value), do: 0

  defp confidence_label(value) when is_integer(value) or is_float(value) do
    :erlang.float_to_binary(value / 1, decimals: 2)
  end

  defp confidence_label(_value), do: "0.00"
end
