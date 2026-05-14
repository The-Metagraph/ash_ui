defmodule LiveUi.Widgets.Toast do
  @moduledoc """
  Native toast widget for transient feedback overlays.
  """

  use LiveUi.Component, family: :overlay, name: :toast, slots: [:inner_block]

  LiveUi.Component.common_attrs()
  attr(:open, :boolean, default: true)
  attr(:placement, :string, default: "top-end")
  attr(:duration_ms, :integer, default: 5000)
  attr(:severity, :string, default: "info")
  attr(:transient, :boolean, default: true)
  slot(:inner_block)

  @impl true
  def render(assigns) do
    ~H"""
    <aside
      id={@id}
      data-live-ui-widget="toast"
      data-live-ui-open={@open}
      data-live-ui-placement={@placement}
      data-live-ui-duration-ms={@duration_ms}
      data-live-ui-severity={@severity}
      data-live-ui-transient={@transient}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </aside>
    """
  end
end
