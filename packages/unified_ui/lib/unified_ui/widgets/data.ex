defmodule UnifiedUi.Widgets.Data do
  @moduledoc """
  Package-facing reference surface for authored data and document widget kinds.
  """

  alias UnifiedUi.Dsl.Entities.Data

  @spec kinds() :: [atom()]
  def kinds do
    Data.kinds()
  end
end
