defmodule LiveUi.Widgets.SplitPane do
  @moduledoc """
  Native split-pane primitive for dual-region display composition.
  """

  use LiveUi.Component, family: :display, name: :split_pane, slots: [:primary, :secondary]

  LiveUi.Component.common_attrs()
  attr(:direction, :string, default: "horizontal")
  attr(:ratio, :float, default: 0.5)
  attr(:resizable, :boolean, default: true)
  attr(:min_primary, :integer, default: nil)
  attr(:min_secondary, :integer, default: nil)
  attr(:divider_size, :integer, default: nil)
  attr(:sync_scroll, :string, default: nil)
  slot(:primary, required: true)
  slot(:secondary, required: true)

  @impl true
  def render(assigns) do
    assigns =
      assign(
        assigns,
        :diagnostics,
        LiveUi.Diagnostics.validate_split_pane(assigns.primary, assigns.secondary)
      )

    ~H"""
    <section
      id={@id}
      data-live-ui-widget="split-pane"
      data-live-ui-direction={@direction}
      data-live-ui-ratio={@ratio}
      data-live-ui-resizable={@resizable}
      data-live-ui-min-primary={@min_primary}
      data-live-ui-min-secondary={@min_secondary}
      data-live-ui-divider-size={@divider_size}
      data-live-ui-sync-scroll={@sync_scroll}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    >
      <LiveUi.Diagnostics.render diagnostics={@diagnostics} />
      <div data-live-ui-split-pane-slot="primary"><%= render_slot(@primary) %></div>
      <div data-live-ui-split-pane-slot="secondary"><%= render_slot(@secondary) %></div>
    </section>
    """
  end
end
