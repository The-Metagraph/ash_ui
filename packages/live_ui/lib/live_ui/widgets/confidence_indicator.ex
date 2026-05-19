defmodule LiveUi.Widgets.ConfidenceIndicator do
  @moduledoc """
  Native confidence indicator widget.
  """

  use LiveUi.Component, family: :feedback, name: :confidence_indicator

  LiveUi.Component.common_attrs()
  attr(:value, :float, required: true)
  attr(:warn_threshold, :float, default: 0.5)
  attr(:pass_threshold, :float, default: 0.8)
  attr(:label, :string, default: nil)
  attr(:show_numeric?, :boolean, default: true)
  attr(:show_glyph?, :boolean, default: true)
  attr(:size, :string, default: "medium")

  @impl true
  def render(assigns) do
    band = band(assigns.value, assigns.warn_threshold, assigns.pass_threshold)
    pct = trunc(assigns.value * 100)
    label = assigns.label || "Confidence: #{pct}%"

    assigns =
      assigns
      |> assign(:band, band)
      |> assign(:pct, pct)
      |> assign(:resolved_label, label)

    ~H"""
    <div
      id={@id}
      data-live-ui-widget="confidence-indicator"
      data-confidence-band={@band}
      data-live-ui-tone={@tone}
      data-live-ui-variant={@variant}
      data-live-ui-state={@state}
      class={[
        "live-ui-confidence",
        "live-ui-confidence--#{@size}",
        "live-ui-confidence--#{@band}",
        @class
      ]}
      role="meter"
      aria-valuenow={@pct}
      aria-valuemin="0"
      aria-valuemax="100"
      aria-label={@resolved_label}
      {@rest}
    >
      <%= if @show_glyph? do %>
        <span class="live-ui-confidence__glyph" aria-hidden="true">
          <%= glyph_for_band(@band) %>
        </span>
      <% end %>

      <div class="live-ui-confidence__bar">
        <div class="live-ui-confidence__bar-fill" style={"width: #{@pct}%"}></div>
      </div>

      <%= if @show_numeric? do %>
        <span class="live-ui-confidence__numeric"><%= @pct %>%</span>
      <% end %>
    </div>
    """
  end

  defp band(value, warn_threshold, pass_threshold) when is_number(value) do
    cond do
      value >= pass_threshold -> "pass"
      value >= warn_threshold -> "warn"
      true -> "fail"
    end
  end

  defp glyph_for_band("pass"), do: "OK"
  defp glyph_for_band("warn"), do: "!"
  defp glyph_for_band(_band), do: "X"
end
