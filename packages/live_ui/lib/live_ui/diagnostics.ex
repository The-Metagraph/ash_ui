defmodule LiveUi.Diagnostics do
  @moduledoc """
  Readable diagnostics for advanced native and canonical display constructs.
  """

  use Phoenix.Component

  alias UnifiedIUR.Element

  @type diagnostic :: %{
          reason: atom(),
          message: String.t(),
          details: map()
        }

  @canvas_operation_kinds [:cell, :fragment, :line, :point, :rect, :text]

  attr(:diagnostics, :list, default: [])

  def render(assigns) do
    ~H"""
    <%= for diagnostic <- @diagnostics do %>
      <p data-live-ui-diagnostic={diagnostic.reason}>
        <%= diagnostic.message %>
      </p>
    <% end %>
    """
  end

  @spec validate_overlay_surface(list()) :: [diagnostic()]
  def validate_overlay_surface(base_slots) when is_list(base_slots) do
    if base_slots == [] do
      [missing_slot(:overlay_surface, :base)]
    else
      []
    end
  end

  @spec validate_context_menu(map(), list()) :: [diagnostic()]
  def validate_context_menu(anchor, items) when is_map(anchor) and is_list(items) do
    []
    |> maybe_add(
      anchor_missing?(anchor),
      invalid_layer_target(%{widget: :context_menu, anchor: anchor})
    )
    |> maybe_add(items == [], missing_slot(:context_menu, :items))
  end

  @spec validate_viewport(list()) :: [diagnostic()]
  def validate_viewport(inner_block) when is_list(inner_block) do
    if inner_block == [] do
      [missing_slot(:viewport, :content)]
    else
      []
    end
  end

  @spec validate_scroll_bar(String.t() | nil) :: [diagnostic()]
  def validate_scroll_bar(nil), do: [missing_display_ref(:scroll_bar, :viewport_ref)]
  def validate_scroll_bar(_viewport_ref), do: []

  @spec validate_split_pane(list(), list()) :: [diagnostic()]
  def validate_split_pane(primary, secondary) when is_list(primary) and is_list(secondary) do
    []
    |> maybe_add(primary == [], missing_slot(:split_pane, :primary))
    |> maybe_add(secondary == [], missing_slot(:split_pane, :secondary))
  end

  @spec validate_canvas(list()) :: [diagnostic()]
  def validate_canvas(operations) when is_list(operations) do
    operations
    |> Enum.with_index()
    |> Enum.reduce([], fn {operation, index}, diagnostics ->
      diagnostics ++ canvas_operation_diagnostics(operation, index)
    end)
  end

  @spec validate_element(Element.t()) :: [diagnostic()]
  def validate_element(%Element{kind: :overlay} = element) do
    validate_overlay_surface(Element.children_for_slot(element, :base))
  end

  def validate_element(%Element{kind: :dialog} = element) do
    validate_required_slot(element, :content, :dialog)
  end

  def validate_element(%Element{kind: :alert_dialog} = element) do
    validate_required_slot(element, :content, :alert_dialog)
  end

  def validate_element(%Element{kind: :toast} = element) do
    validate_required_slot(element, :content, :toast)
  end

  def validate_element(%Element{kind: :context_menu} = element) do
    validate_context_menu(
      get_in(element.attributes, [:context_menu, :anchor]) || %{},
      Element.children_for_slot(element, :menu)
    )
  end

  def validate_element(%Element{kind: :viewport} = element) do
    validate_required_slot(element, :content, :viewport)
  end

  def validate_element(%Element{kind: :scroll_bar} = element) do
    validate_scroll_bar(get_in(element.attributes, [:scroll_bar, :viewport_ref]))
  end

  def validate_element(%Element{kind: :split_pane} = element) do
    validate_split_pane(
      Element.children_for_slot(element, :primary),
      Element.children_for_slot(element, :secondary)
    )
  end

  def validate_element(%Element{kind: :canvas} = element) do
    validate_canvas(get_in(element.attributes, [:canvas, :operations]) || [])
  end

  def validate_element(%Element{}), do: []

  defp validate_required_slot(%Element{} = element, slot, kind) do
    if Element.children_for_slot(element, slot) == [] do
      [missing_slot(kind, slot)]
    else
      []
    end
  end

  defp canvas_operation_diagnostics(operation, index) do
    operation = Map.new(operation)
    kind = Map.get(operation, :kind) || Map.get(operation, "kind")

    has_geometry? =
      present?(Map.get(operation, :position) || Map.get(operation, "position")) or
        present?(Map.get(operation, :points) || Map.get(operation, "points"))

    []
    |> maybe_add(
      kind not in @canvas_operation_kinds,
      invalid_canvas_operation(index, "unsupported canvas operation kind")
    )
    |> maybe_add(
      not has_geometry?,
      invalid_canvas_operation(index, "canvas operation requires position or points")
    )
  end

  defp missing_slot(kind, slot) do
    %{
      reason: :missing_slot,
      message: "#{kind} requires a #{slot} slot to render correctly",
      details: %{kind: kind, slot: slot}
    }
  end

  defp missing_display_ref(kind, ref) do
    %{
      reason: :missing_display_ref,
      message: "#{kind} requires #{ref} to stay connected to its display target",
      details: %{kind: kind, ref: ref}
    }
  end

  defp invalid_layer_target(details) do
    %{
      reason: :invalid_layer_target,
      message: "layered widgets require an anchor target_id or explicit x/y coordinates",
      details: details
    }
  end

  defp invalid_canvas_operation(index, message) do
    %{
      reason: :invalid_canvas_operation,
      message: "canvas operation #{index} is invalid: #{message}",
      details: %{index: index}
    }
  end

  defp anchor_missing?(anchor) do
    target_id = Map.get(anchor, :target_id) || Map.get(anchor, "target_id")
    x = Map.get(anchor, :x) || Map.get(anchor, "x")
    y = Map.get(anchor, :y) || Map.get(anchor, "y")

    is_nil(target_id) and (is_nil(x) or is_nil(y))
  end

  defp present?(nil), do: false
  defp present?([]), do: false
  defp present?(_value), do: true

  defp maybe_add(diagnostics, true, diagnostic), do: diagnostics ++ [diagnostic]
  defp maybe_add(diagnostics, false, _diagnostic), do: diagnostics
end
