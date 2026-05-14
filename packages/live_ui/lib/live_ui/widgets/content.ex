defmodule LiveUi.Widgets.Content do
  @moduledoc """
  Baseline content-bearing native widget for arbitrary child content.
  """

  use LiveUi.Component, family: :content, name: :content, slots: [:inner_block]

  LiveUi.Component.common_attrs()
  attr(:role, :string, default: "content")
  slot(:inner_block)

  @impl true
  def render(assigns) do
    ~H"""
    <article
      id={@id}
      data-live-ui-widget="content"
      data-live-ui-role={@role}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </article>
    """
  end
end
