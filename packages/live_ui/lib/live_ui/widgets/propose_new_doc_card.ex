defmodule LiveUi.Widgets.ProposeNewDocCard do
  @moduledoc """
  Native proposal card for an agent-authored document draft.

  The widget renders the canonical `:propose_new_doc_card` callout shape and
  leaves accept, reject, and preview transport to renderer-supplied interaction
  attributes.
  """

  use LiveUi.Component,
    family: :layer_shell_and_callout,
    name: :propose_new_doc_card,
    slots: [],
    events: [:accept, :reject, :preview, :body_toggled, :conversation_seed_toggled]

  LiveUi.Component.common_attrs()
  attr(:target_path, :string, required: true)
  attr(:title, :string, required: true)
  attr(:body_md_preview, :string, required: true)
  attr(:body_md, :string, default: nil)
  attr(:status, :atom, required: true)
  attr(:conversation_seed_md, :string, default: nil)
  attr(:actor_handle, :string, default: nil)
  attr(:proposed_at, :string, default: nil)
  attr(:expanded?, :boolean, default: false)
  attr(:seed_expanded?, :boolean, default: false)
  attr(:accept_attrs, :any, default: [])
  attr(:reject_attrs, :any, default: [])
  attr(:preview_attrs, :any, default: [])
  attr(:body_toggle_attrs, :any, default: [])
  attr(:seed_toggle_attrs, :any, default: [])

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(:body_id, "#{assigns.id}-body")
      |> assign(:seed_id, "#{assigns.id}-conversation-seed")
      |> assign(:full_body?, full_body_available?(assigns.body_md, assigns.body_md_preview))
      |> assign(:status_text, status_label(assigns.status))

    ~H"""
    <article
      id={@id}
      data-live-ui-widget="propose-new-doc-card"
      data-status={@status}
      data-target-path={@target_path}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={propose_new_doc_card_class(@class, @status)}
      aria-label={"Proposed document #{@title}, #{@status_text}"}
      {@rest}
    >
      <header class="live-ui-propose-new-doc-card__header">
        <div class="live-ui-propose-new-doc-card__identity">
          <h3 class="live-ui-propose-new-doc-card__title"><%= @title %></h3>
          <span
            :if={@actor_handle}
            class="live-ui-propose-new-doc-card__actor"
          >
            <%= @actor_handle %>
          </span>
          <time
            :if={@proposed_at}
            class="live-ui-propose-new-doc-card__proposed-at"
            datetime={@proposed_at}
          >
            <%= @proposed_at %>
          </time>
        </div>
        <span
          class={["live-ui-propose-new-doc-card__status-badge", status_class(@status)]}
          role="status"
        >
          <%= @status_text %>
        </span>
      </header>

      <p class="live-ui-propose-new-doc-card__target-path font-mono">
        <%= @target_path %>
      </p>

      <section
        id={@body_id}
        class="live-ui-propose-new-doc-card__body"
        aria-label={"Draft preview for #{@title}"}
      >
        <pre class="live-ui-propose-new-doc-card__body-preview"><%= body_text(@body_md_preview, @body_md, @expanded?) %></pre>
      </section>

      <button
        :if={@full_body?}
        type="button"
        class="live-ui-propose-new-doc-card__body-toggle"
        aria-expanded={boolean_string(@expanded?)}
        aria-controls={@body_id}
        {toggle_attrs(@body_toggle_attrs, "body_toggled")}
      >
        <%= if @expanded?, do: "Show preview", else: "Show full draft" %>
      </button>

      <section
        :if={@conversation_seed_md}
        class="live-ui-propose-new-doc-card__conversation"
      >
        <button
          type="button"
          class="live-ui-propose-new-doc-card__conversation-toggle"
          aria-expanded={boolean_string(@seed_expanded?)}
          aria-controls={@seed_id}
          {toggle_attrs(@seed_toggle_attrs, "conversation_seed_toggled")}
        >
          Conversation seed
        </button>
        <pre
          id={@seed_id}
          hidden={not @seed_expanded?}
          class="live-ui-propose-new-doc-card__conversation-seed"
        ><%= preview_text(@conversation_seed_md) %></pre>
      </section>

      <footer class="live-ui-propose-new-doc-card__actions">
        <%= if @status == :pending do %>
          <button
            type="button"
            class="live-ui-propose-new-doc-card__accept"
            aria-label={"Accept proposed document #{@title}"}
            {action_attrs(@accept_attrs, "accept")}
          >
            Accept
          </button>
          <button
            type="button"
            class="live-ui-propose-new-doc-card__reject"
            aria-label={"Reject proposed document #{@title}"}
            {action_attrs(@reject_attrs, "reject")}
          >
            Reject
          </button>
        <% else %>
          <p class="live-ui-propose-new-doc-card__locked-message" role="status">
            <%= locked_message(@status) %>
          </p>
        <% end %>

        <button
          type="button"
          class="live-ui-propose-new-doc-card__preview"
          aria-label={"Preview proposed document #{@title}"}
          {action_attrs(@preview_attrs, "preview")}
        >
          Preview
        </button>
      </footer>
    </article>
    """
  end

  defp propose_new_doc_card_class(extra_class, status) do
    [
      "live-ui-propose-new-doc-card",
      "live-ui-propose-new-doc-card--#{status}",
      extra_class
    ]
  end

  defp status_class(nil), do: nil
  defp status_class(status), do: "live-ui-propose-new-doc-card__status-badge--#{status}"

  defp status_label(status) do
    status
    |> to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp locked_message(:accepted), do: "This proposal has been accepted."
  defp locked_message(:rejected), do: "This proposal has been rejected."
  defp locked_message(:archived), do: "This proposal has been archived."
  defp locked_message(status), do: "This proposal is #{status_label(status)}."

  defp full_body_available?(body_md, body_md_preview) do
    is_binary(body_md) and body_md != "" and body_md != body_md_preview
  end

  defp body_text(_preview, body_md, true) when is_binary(body_md), do: body_md
  defp body_text(preview, _body_md, _expanded?), do: preview_text(preview)

  defp preview_text(text) when is_binary(text) do
    if String.length(text) > 360 do
      String.slice(text, 0, 360) <> "..."
    else
      text
    end
  end

  defp preview_text(_text), do: ""

  defp boolean_string(true), do: "true"
  defp boolean_string(_), do: "false"

  defp action_attrs(attrs, fallback_event), do: fallback_attrs(attrs, fallback_event)
  defp toggle_attrs(attrs, fallback_event), do: fallback_attrs(attrs, fallback_event)

  defp fallback_attrs(attrs, fallback_event) when attrs in [nil, [], %{}],
    do: %{:"phx-click" => fallback_event}

  defp fallback_attrs(attrs, _fallback_event), do: attrs
end
