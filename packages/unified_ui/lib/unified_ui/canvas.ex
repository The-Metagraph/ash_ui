defmodule UnifiedUi.Canvas do
  @moduledoc """
  Package-facing reference surface for authored canvas kinds.
  """

  alias UnifiedUi.Dsl.Entities.Canvas

  @spec kinds() :: [atom()]
  def kinds do
    Canvas.kinds()
  end
end
