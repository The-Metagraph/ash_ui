defmodule LiveUi.Widgets.Advanced do
  @moduledoc """
  Reference surface for advanced native widget families.
  """

  @spec modules() :: [module()]
  def modules do
    LiveUi.Widgets.Data.modules() ++
      LiveUi.Widgets.Feedback.modules() ++
      LiveUi.Widgets.Operational.modules()
  end
end
