defmodule LiveUi.Widgets.ThreadCard do
  @moduledoc """
  Native thread-card widget.

  Renders a rich preview card for a conversation thread reference. Used wherever
  a thread is mentioned in another conversation's feed (Chat references section,
  Talk cross-thread mentions, Map per-repo activity), showing enough context that
  the operator can decide whether to navigate into it without doing so.

  ## Attributes

  Required:
  - `:thread_id` - the conversation/thread identifier (data selector hook)
  - `:title` - the thread's display title
  - `:reply_count` - total replies in the thread
  - `:seed_quote` - a pull quote from the thread's opening message

  Optional:
  - `:participants` - list of `%{avatar: avatar_attrs, actor_name: string}` maps for
    the avatar stack; at most 3 are shown with an overflow indicator
  - `:progress_pct` - float 0.0–1.0; when present renders an inline progress bar
  - `:last_activity_at` - DateTime for relative-time subtext
  - `:open_intent` - canonical Interaction intent for the open action (default "open_thread")

  ## Selector / hook contract

  Root element: `data-live-ui-widget="thread-card"` + `data-thread-id="{id}"`.
  Avatar stack: `.live-ui-thread-card__avatars` + `.live-ui-thread-card__avatar` per BEM.
  Inline progress: `.live-ui-thread-card__progress` + `[data-progress-pct]`.
  Open action: `.live-ui-thread-card__open` + `aria-label="Open thread: {title}"`.
  Avatar overflow: `.live-ui-thread-card__avatar-overflow` + aria-label.

  ## ARIA

  - The open-thread button: `aria-label="Open thread: {title}"`.
  - Avatar overflow span: `aria-label="and N more participants"`.
  - Progress bar (when present): `role="progressbar" aria-valuenow aria-valuemin aria-valuemax`.
  - The article root uses an implicit `region` role (no explicit ARIA needed).

  ## Open questions for Pascal (Wave 3.7-B)

  1. **Family assignment** — placed in `:content_identity_and_disclosure` per spec draft; Pascal
     may prefer a new `:conversation_artifact` family or another existing family.
  2. **Participants as attr vs children** — kept in element attrs (not as child IUR nodes) since
     participants aren't independently interactive in v1. Pascal may prefer child `:avatar` nodes
     for composability.
  3. **Seed-quote truncation** — truncation is render-side here (via CSS or explicit slice in the
     template). Pascal may want a constructor-enforced max-length.
  4. **Progress bar reuse** — inline progress is bespoke in this template (not a child `:progress`
     IUR widget). Reuse via a nested `LiveUi.Widgets.Progress` would be more compositional.
  5. **"Open →" affordance** — text+arrow string is locked in the renderer here; Pascal may want it
     themable or icon-based.
  """

  use LiveUi.Component, family: :content, name: :thread_card, events: [:click]

  LiveUi.Component.common_attrs()
  attr(:thread_id, :string, required: true)
  attr(:title, :string, required: true)
  attr(:reply_count, :integer, default: 0)
  attr(:seed_quote, :string, default: "")
  attr(:participants, :list, default: [])
  attr(:progress_pct, :float, default: nil)
  attr(:last_activity_at, :any, default: nil)
  attr(:open_intent, :string, default: "open_thread")

  @impl true
  def render(assigns) do
    ~H"""
    <article
      id={@id}
      data-live-ui-widget="thread-card"
      data-thread-id={@thread_id}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={["live-ui-thread-card", @class]}
      {@rest}
    >
      <header class="live-ui-thread-card__header">
        <div
          class="live-ui-thread-card__avatars"
          aria-hidden="true"
        >
          <%= for participant <- Enum.take(@participants, 3) do %>
            <span
              class="live-ui-thread-card__avatar"
              title={Map.get(participant, :actor_name) || Map.get(participant, "actor_name") || ""}
            >
              {participant_initials(participant)}
            </span>
          <% end %>
          <%= if length(@participants) > 3 do %>
            <span
              class="live-ui-thread-card__avatar-overflow"
              aria-label={"and #{length(@participants) - 3} more participants"}
            >
              +{length(@participants) - 3}
            </span>
          <% end %>
        </div>
        <h3 class="live-ui-thread-card__title">{@title}</h3>
      </header>

      <blockquote class="live-ui-thread-card__seed-quote">{@seed_quote}</blockquote>

      <%= if @progress_pct do %>
        <div
          class="live-ui-thread-card__progress"
          role="progressbar"
          aria-valuenow={trunc(@progress_pct * 100)}
          aria-valuemin="0"
          aria-valuemax="100"
          data-progress-pct={@progress_pct}
        >
          <div
            class="live-ui-thread-card__progress-fill"
            style={"width: #{trunc(@progress_pct * 100)}%"}
          />
        </div>
      <% end %>

      <footer class="live-ui-thread-card__footer">
        <span class="live-ui-thread-card__meta">
          {@reply_count} {ngettext_fallback(@reply_count)}<%= if @last_activity_at do %> · {relative_time(@last_activity_at)}<% end %>
        </span>
        <button
          type="button"
          class="live-ui-thread-card__open"
          aria-label={"Open thread: #{@title}"}
          data-live-ui-intent={@open_intent}
          data-live-ui-value={@thread_id}
          {@rest}
        >
          open →
        </button>
      </footer>
    </article>
    """
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp participant_initials(participant) do
    actor_name =
      Map.get(participant, :actor_name) ||
        Map.get(participant, "actor_name") || ""

    avatar = Map.get(participant, :avatar) || Map.get(participant, "avatar") || %{}
    initials = Map.get(avatar, :initials) || Map.get(avatar, "initials")

    cond do
      is_binary(initials) and initials != "" ->
        initials

      is_binary(actor_name) and actor_name != "" ->
        actor_name
        |> String.split()
        |> Enum.take(2)
        |> Enum.map(&String.first/1)
        |> Enum.join()
        |> String.upcase()

      true ->
        "?"
    end
  end

  defp ngettext_fallback(1), do: "reply"
  defp ngettext_fallback(_), do: "replies"

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
