defmodule UnifiedUi.Layer do
  @moduledoc """
  Package-facing reference surface for authored overlay and layer-driven widget kinds.
  """

  alias UnifiedUi.Dsl.Entities.Overlay

  @spec kinds() :: [atom()]
  def kinds do
    Overlay.kinds()
  end
end
