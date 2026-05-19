defmodule LiveUi.Widgets.WorkflowProgressAndStatus do
  @moduledoc """
  Reference surface for canonical workflow progress and status widgets.
  """

  @modules [
    LiveUi.Widgets.WorkflowProgressStatusCard
  ]

  @spec modules() :: [module()]
  def modules, do: @modules
end
