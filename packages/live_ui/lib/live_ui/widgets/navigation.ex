defmodule LiveUi.Widgets.Navigation do
  @moduledoc """
  Reference surface for foundational navigation widgets.
  """

  @modules [
    LiveUi.Widgets.Menu,
    LiveUi.Widgets.Tabs,
    LiveUi.Widgets.CommandPalette,
    LiveUi.Widgets.DocRightRail
  ]

  @spec modules() :: [module()]
  def modules do
    @modules
  end
end
