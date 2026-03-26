defmodule UnifiedUi.Widgets.Advanced do
  @moduledoc """
  Package-facing reference surface for authored operational and diagnostic widget kinds.
  """

  alias UnifiedUi.Dsl.Entities.Advanced

  @spec kinds() :: [atom()]
  def kinds do
    Advanced.kinds()
  end
end
