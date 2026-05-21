defmodule LiveUi.Widgets.LayerShellAndCallout do
  @moduledoc """
  Reference surface for canonical layer shell and callout widgets.
  """

  @modules [
    LiveUi.Widgets.RightRail,
    LiveUi.Widgets.SidebarSection,
    LiveUi.Widgets.ComposerQueryPreview
  ]

  @spec modules() :: [module()]
  def modules, do: @modules
end
