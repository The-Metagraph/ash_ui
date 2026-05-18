defmodule LiveUi.Widgets.Workflow do
  @moduledoc """
  Reference surface for workflow-oriented widgets.
  """

  @modules [
    LiveUi.Widgets.NeedsYouSection
  ]

  @spec modules() :: [module()]
  def modules, do: @modules
end
