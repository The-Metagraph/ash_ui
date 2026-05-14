defmodule LiveUi.Widgets.Input do
  @moduledoc """
  Reference surface for foundational input widgets.
  """

  @modules [
    LiveUi.Widgets.TextInput,
    LiveUi.Widgets.Toggle,
    LiveUi.Widgets.Select
  ]

  @spec modules() :: [module()]
  def modules do
    @modules
  end
end
