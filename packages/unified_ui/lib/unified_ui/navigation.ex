defmodule UnifiedUi.Navigation do
  @moduledoc """
  Package-facing reference surface for authored navigation widget kinds.
  """

  alias UnifiedUi.Dsl.Entities.Navigation

  @spec kinds() :: [atom()]
  def kinds do
    Navigation.kinds()
  end
end
