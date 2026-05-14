defmodule ElmUi.Renderer do
  @moduledoc """
  Canonical `UnifiedIUR` renderer entrypoint for `elm_ui`.
  """

  alias UnifiedIUR.Element
  alias ElmUi.Renderer.Error

  @spec accepts() :: module()
  def accepts, do: Element

  @spec responsibilities() :: [atom()]
  def responsibilities do
    [
      :accept_canonical_iur,
      :deterministic_native_mapping,
      :native_widget_reuse,
      :advanced_widget_reuse,
      :layered_runtime_coordination,
      :coverage_oriented_diagnostics
    ]
  end

  @spec required_canonical_kinds() :: [atom()]
  def required_canonical_kinds do
    [
      UnifiedIUR.Widgets.Foundational.kinds(),
      UnifiedIUR.Widgets.Input.kinds(),
      UnifiedIUR.Widgets.Navigation.kinds(),
      UnifiedIUR.Forms.kinds(),
      UnifiedIUR.Layout.kinds(),
      UnifiedIUR.Viewport.kinds(),
      UnifiedIUR.Widgets.Data.kinds(),
      UnifiedIUR.Widgets.Feedback.kinds(),
      UnifiedIUR.Canvas.kinds(),
      UnifiedIUR.Widgets.Advanced.kinds(),
      UnifiedIUR.Layer.kinds()
    ]
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.sort()
  end

  @spec supported_kinds() :: [atom()]
  def supported_kinds do
    required_canonical_kinds()
    |> Kernel.++([:container, :form, :panel])
    |> Enum.uniq()
    |> Enum.sort()
  end

  @spec render(Element.t(), keyword()) :: {:ok, ElmUi.Widget.t()} | {:error, Error.t()}
  def render(%Element{} = element, opts \\ []) do
    ElmUi.Renderer.Canonical.render(element, opts)
  end
end
