defmodule LiveUi.Widgets.Data do
  @moduledoc """
  Reference surface for advanced data and document widgets.
  """

  @modules [
    LiveUi.Widgets.List,
    LiveUi.Widgets.Table,
    LiveUi.Widgets.TreeView,
    LiveUi.Widgets.MarkdownViewer,
    LiveUi.Widgets.LogViewer,
    LiveUi.Widgets.ArtifactRow
  ]

  @spec modules() :: [module()]
  def modules, do: @modules
end
