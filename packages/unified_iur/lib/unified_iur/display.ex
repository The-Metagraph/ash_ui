defmodule UnifiedIUR.Display do
  @moduledoc """
  Reference surface for advanced canonical display-system constructors exposed by
  `UnifiedIUR`.
  """

  @spec modules() :: %{canvas: module(), layer: module(), viewport: module()}
  def modules do
    %{
      layer: UnifiedIUR.Layer,
      viewport: UnifiedIUR.Viewport,
      canvas: UnifiedIUR.Canvas
    }
  end
end
