defmodule UnifiedUi.Widgets.Feedback do
  @moduledoc """
  Package-facing reference surface for authored feedback and chart widget kinds.
  """

  alias UnifiedUi.Dsl.Entities.Feedback

  @spec kinds() :: [atom()]
  def kinds do
    Feedback.kinds()
  end
end
