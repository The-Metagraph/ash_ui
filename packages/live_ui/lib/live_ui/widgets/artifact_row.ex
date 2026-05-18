defmodule LiveUi.Widgets.ArtifactRow do
  @moduledoc """
  Native artifact row widget.

  Generic row primitive for any named artifact (PR, doc, spec, file, grain, etc.)
  in a list context. Renders title + meta (kind glyph, status badges, count chips,
  timestamp) plus an optional trailing actions slot.

  ## Semantic style intent

  - `kind` — artifact kind atom; drives glyph and `data-artifact-kind` hook.
    One of: `:pr | :doc | :spec | :file | :grain | :generic`.
  - `tone` — overall row tone (`:neutral | :positive | :warning | :danger | :info`).
  - `selected?` — whether the row is in a selected state; sets `aria-selected` +
    CSS state modifier.

  ## Props fed from UnifiedIUR

  Attributes arrive under `element.attributes[:artifact]`:
  - `:title` — row heading text (required at IUR authoring; defaults gracefully here)
  - `:meta` — freeform display string for secondary meta text
  - `:row_identity` — opaque row identity for DOM scoping
  - `:active?` — whether the row is in an active/hovered state
  - `:link_target` — optional href; renders row as a navigation target
  - `:action_intent` — primary interaction intent descriptor

  ## Design open questions (Pascal review required)

  `status_badges`, `counts`, and `timestamp_at` are first-class canonical
  artifact attributes. Row-level interactions arrive through the canonical
  `attributes.interactions` attachment and are translated into global attrs by
  `LiveUi.Renderer`; trailing actions are child elements rendered in the
  `:actions` slot.
  """

  use LiveUi.Component, family: :data, name: :artifact_row, slots: [:actions], events: [:click]

  LiveUi.Component.common_attrs()
  attr(:title, :string, required: true)
  attr(:subtitle, :string, default: nil)
  attr(:kind, :atom, default: :generic)
  attr(:status_badges, :list, default: [])
  attr(:counts, :any, default: [])
  attr(:timestamp_at, :any, default: nil)
  attr(:selected?, :boolean, default: false)
  attr(:active?, :boolean, default: false)
  slot(:actions)

  @impl true
  def render(assigns) do
    ~H"""
    <article
      id={@id}
      data-live-ui-widget="artifact-row"
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      data-artifact-kind={@kind}
      aria-selected={if @selected?, do: "true", else: "false"}
      class={artifact_row_class(@class, @kind, @selected?, @active?)}
      {@rest}
    >
      <span class="live-ui-artifact-row__glyph" aria-hidden="true"><%= glyph_for_kind(@kind) %></span>
      <div class="live-ui-artifact-row__body">
        <h4 class="live-ui-artifact-row__title"><%= @title %></h4>
        <%= if @subtitle do %>
          <p class="live-ui-artifact-row__subtitle"><%= @subtitle %></p>
        <% end %>
        <div class="live-ui-artifact-row__meta">
          <%= for badge <- @status_badges do %>
            <span class={["live-ui-artifact-row__status-badge", badge_tone_class(badge[:tone] || badge["tone"])]}>
              <%= badge[:label] || badge["label"] %>
            </span>
          <% end %>
          <%= for count <- normalize_counts(@counts) do %>
            <span class="live-ui-artifact-row__count" data-count-key={count_key(count)}>
              <%= count_label(count) %>
            </span>
          <% end %>
          <%= if @timestamp_at do %>
            <time
              class="live-ui-artifact-row__timestamp"
              datetime={timestamp_iso8601(@timestamp_at)}
            >
              <%= relative_time(@timestamp_at) %>
            </time>
          <% end %>
        </div>
      </div>
      <%= if @actions != [] do %>
        <div class="live-ui-artifact-row__actions">
          <%= render_slot(@actions) %>
        </div>
      <% end %>
    </article>
    """
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp artifact_row_class(extra_class, kind, selected?, active?) do
    base = "live-ui-artifact-row"
    kind_class = "live-ui-artifact-row--#{kind}"

    modifiers =
      []
      |> maybe_append(selected?, "is-selected")
      |> maybe_append(active?, "is-active")

    [base, kind_class] ++ modifiers ++ List.wrap(extra_class)
  end

  defp maybe_append(list, true, class), do: [class | list]
  defp maybe_append(list, _false, _class), do: list

  defp glyph_for_kind(:pr), do: "↳"
  defp glyph_for_kind(:doc), do: "❐"
  defp glyph_for_kind(:spec), do: "✓"
  defp glyph_for_kind(:file), do: "□"
  defp glyph_for_kind(:grain), do: "◆"
  defp glyph_for_kind(:generic), do: "○"
  defp glyph_for_kind(_other), do: "○"

  defp badge_tone_class(nil), do: nil
  defp badge_tone_class(tone), do: "is-tone-#{tone}"

  defp timestamp_iso8601(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp timestamp_iso8601(%NaiveDateTime{} = ndt), do: NaiveDateTime.to_iso8601(ndt)
  defp timestamp_iso8601(value) when is_binary(value), do: value
  defp timestamp_iso8601(_other), do: nil

  defp relative_time(%DateTime{} = dt) do
    diff_seconds = DateTime.diff(DateTime.utc_now(), dt)
    format_seconds(diff_seconds)
  end

  defp relative_time(%NaiveDateTime{} = ndt) do
    now = NaiveDateTime.utc_now()
    diff_seconds = NaiveDateTime.diff(now, ndt)
    format_seconds(diff_seconds)
  end

  defp relative_time(value) when is_binary(value), do: value
  defp relative_time(_other), do: ""

  defp format_seconds(s) when s < 60, do: "just now"
  defp format_seconds(s) when s < 3600, do: "#{div(s, 60)}m ago"
  defp format_seconds(s) when s < 86_400, do: "#{div(s, 3600)}h ago"
  defp format_seconds(s), do: "#{div(s, 86_400)}d ago"

  defp normalize_counts(nil), do: []

  defp normalize_counts(counts) when is_map(counts) do
    counts
    |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
    |> Enum.map(fn {key, value} -> %{key: key, value: value} end)
  end

  defp normalize_counts(counts) when is_list(counts) do
    Enum.map(counts, &normalize_count/1)
  end

  defp normalize_counts(_other), do: []

  defp normalize_count({key, value}), do: %{key: key, value: value}

  defp normalize_count(count) when is_map(count) do
    %{
      key: Map.get(count, :key, Map.get(count, "key")),
      value: Map.get(count, :value, Map.get(count, "value")),
      label: Map.get(count, :label, Map.get(count, "label"))
    }
  end

  defp normalize_count(count) when is_list(count), do: count |> Map.new() |> normalize_count()
  defp normalize_count(_other), do: %{}

  defp count_key(count), do: Map.get(count, :key)

  defp count_label(count) do
    Map.get(count, :label) || Map.get(count, :value)
  end
end
