defmodule LiveUi.Widgets.Operational do
  @moduledoc """
  Reference surface for operational and monitoring widgets.
  """

  @modules [
    LiveUi.Widgets.StreamWidget,
    LiveUi.Widgets.ProcessMonitor,
    LiveUi.Widgets.SupervisionTreeViewer,
    LiveUi.Widgets.ClusterDashboard
  ]

  @spec modules() :: [module()]
  def modules, do: @modules
end
