defmodule LiveUi.Widgets.Feedback do
  @moduledoc """
  Reference surface for advanced feedback and chart widgets.
  """

  @modules [
    LiveUi.Widgets.Status,
    LiveUi.Widgets.Progress,
    LiveUi.Widgets.Gauge,
    LiveUi.Widgets.InlineFeedback,
    LiveUi.Widgets.DiffBanner,
    LiveUi.Widgets.ConfidenceIndicator,
    LiveUi.Widgets.Sparkline,
    LiveUi.Widgets.BarChart,
    LiveUi.Widgets.LineChart
  ]

  @spec modules() :: [module()]
  def modules, do: @modules
end
