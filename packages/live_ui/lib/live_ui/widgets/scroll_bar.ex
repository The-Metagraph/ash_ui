defmodule LiveUi.Widgets.ScrollBar do
  @moduledoc """
  Native scroll-bar primitive tied to a viewport or scroll region.
  """

  use LiveUi.Component, family: :display, name: :scroll_bar, events: [:change]

  LiveUi.Component.common_attrs()
  attr(:orientation, :string, default: "vertical")
  attr(:position_start, :float, default: 0.0)
  attr(:position_end, :float, default: 0.0)
  attr(:viewport_size, :integer, default: nil)
  attr(:content_size, :integer, default: nil)
  attr(:viewport_ref, :string, default: nil)
  attr(:sync_group, :string, default: nil)

  @impl true
  def render(assigns) do
    assigns =
      assign(assigns, :diagnostics, LiveUi.Diagnostics.validate_scroll_bar(assigns.viewport_ref))

    ~H"""
    <div
      id={@id}
      data-live-ui-widget="scroll-bar"
      data-live-ui-orientation={@orientation}
      data-live-ui-position-start={@position_start}
      data-live-ui-position-end={@position_end}
      data-live-ui-viewport-size={@viewport_size}
      data-live-ui-content-size={@content_size}
      data-live-ui-viewport-ref={@viewport_ref}
      data-live-ui-sync-group={@sync_group}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    >
      <LiveUi.Diagnostics.render diagnostics={@diagnostics} />
    </div>
    """
  end
end
