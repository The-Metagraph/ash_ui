defmodule LiveUi.Forms.FormBuilder do
  @moduledoc """
  Baseline native form builder component.
  """

  use LiveUi.Component,
    family: :input,
    name: :form_builder,
    slots: [:inner_block],
    events: [:submit, :change]

  LiveUi.Component.common_attrs()
  attr(:autocomplete, :boolean, default: true)
  slot(:inner_block)

  @impl true
  def render(assigns) do
    ~H"""
    <form
      id={@id}
      data-live-ui-widget="form-builder"
      data-live-ui-autocomplete={@autocomplete}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={@class}
      autocomplete={if @autocomplete, do: "on", else: "off"}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </form>
    """
  end
end
