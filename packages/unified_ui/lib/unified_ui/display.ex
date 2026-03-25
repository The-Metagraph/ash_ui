defmodule UnifiedUi.Display do
  @moduledoc """
  Package-facing reference surface for authored display-system kinds.
  """

  alias UnifiedUi.Dsl.Entities.Display

  @spec kinds() :: [atom()]
  def kinds do
    Display.kinds()
  end
end
