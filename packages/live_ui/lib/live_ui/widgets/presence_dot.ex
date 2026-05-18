defmodule LiveUi.Widgets.PresenceDot do
  @moduledoc """
  Canonical presence-dot widget.

  Renders a small indicator dot that communicates a user's current presence
  state (`:active`, `:away`, `:offline`, or `:focus`). Typically composed
  alongside an Avatar in a me-id footer or user-list row.

  Visual state variants are controlled entirely through CSS:

      .live-ui-presence-dot[data-presence-state="active"] { ... }
      .live-ui-presence-dot[data-presence-state="away"]   { ... }
      .live-ui-presence-dot[data-presence-state="offline"] { ... }
      .live-ui-presence-dot[data-presence-state="focus"]  { ... }

  ## ARIA

  By default the element has an `aria-label` derived from its state, e.g.
  `"Presence: active"`. Pass an explicit `aria_label` string to override.

  Pass `aria_label: false` (the atom `false`, not the string `"false"`) to
  mark the dot as purely decorative: the element will gain `aria-hidden="true"`
  and no `aria-label` attribute will be emitted.

  ## Usage

      <LiveUi.Widgets.PresenceDot.component id="me-presence" presence_state={:active} />
      <LiveUi.Widgets.PresenceDot.component id="me-presence" presence_state={:focus} aria_label="You are in focus mode" />
      <LiveUi.Widgets.PresenceDot.component id="avatar-presence" presence_state={:offline} aria_label={false} />
  """

  use LiveUi.Component, family: :feedback, name: :presence_dot

  LiveUi.Component.common_attrs()

  attr(:presence_state, :atom,
    default: :offline,
    doc: "Presence state: :active | :away | :offline | :focus"
  )

  attr(:aria_label, :any,
    default: nil,
    doc: "Override aria-label; pass false for decorative-only (aria-hidden)"
  )

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :resolved_aria, resolve_aria(assigns))

    ~H"""
    <span
      id={@id}
      class={["live-ui-presence-dot", @class]}
      data-live-ui-widget="presence_dot"
      data-presence-state={@presence_state}
      aria-hidden={if @resolved_aria == :hidden, do: "true"}
      aria-label={if @resolved_aria != :hidden, do: @resolved_aria}
      {@rest}
    ></span>
    """
  end

  # Returns :hidden when decorative-only, or the string aria-label to use.
  defp resolve_aria(%{aria_label: false}), do: :hidden
  defp resolve_aria(%{aria_label: label}) when is_binary(label) and label != "", do: label
  defp resolve_aria(%{presence_state: state}), do: derived_label(state)

  defp derived_label(:active), do: "Presence: active"
  defp derived_label(:away), do: "Presence: away"
  defp derived_label(:offline), do: "Presence: offline"
  defp derived_label(:focus), do: "Presence: focus"
  defp derived_label(other), do: "Presence: #{other}"
end
