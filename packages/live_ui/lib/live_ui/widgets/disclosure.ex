defmodule LiveUi.Widgets.Disclosure do
  @moduledoc """
  Native disclosure widget using the HTML `<details>` / `<summary>` primitive.

  Renders a browser-native collapsible section.  No JavaScript required for
  open/close behaviour; the `open?` attribute controls the initial state only.

  ## Slots

  * `summary` (optional) — content placed inside `<summary>`.  When empty the
    `label` attr is used as a text fallback.
  * `body` (required) — content rendered inside the disclosure body `<div>`.

  ## Canonical contract

  Disclosure is part of the canonical `:content_identity_and_disclosure`
  family. Native `<details>` semantics cover the primitive itself; parent-owned
  accordion or controller widgets can add explicit control linkage when needed.
  Both summary content forms are supported: the `summary` slot takes precedence
  over the `label` attr, which acts as a plain-text fallback.
  """

  use LiveUi.Component,
    family: :content_identity_and_disclosure,
    name: :disclosure,
    slots: [:summary, :body]

  LiveUi.Component.common_attrs()
  attr(:open?, :boolean, default: false)
  attr(:label, :string, default: nil)

  slot(:summary)
  slot(:body, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <details
      id={@id}
      class={["live-ui-disclosure", @class]}
      data-live-ui-widget="disclosure"
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      open={@open?}
      {@rest}
    >
      <summary class="live-ui-disclosure-summary">
        <%= if @summary != [] do %>
          <%= render_slot(@summary) %>
        <% else %>
          <%= @label %>
        <% end %>
      </summary>
      <div class="live-ui-disclosure-body">
        <%= render_slot(@body) %>
      </div>
    </details>
    """
  end
end
