defmodule UnifiedUi.Layout do
  @moduledoc """
  Package-facing reference surface for authored layout kinds.
  """

  alias UnifiedUi.Dsl.Entities.Layout

  @spec kinds() :: [atom()]
  def kinds do
    Layout.kinds()
  end
end
