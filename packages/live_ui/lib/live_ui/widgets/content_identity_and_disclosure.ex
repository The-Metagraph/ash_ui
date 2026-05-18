defmodule LiveUi.Widgets.ContentIdentityAndDisclosure do
  @moduledoc """
  Reference surface for canonical content identity and disclosure widgets.
  """

  @modules [
    LiveUi.Widgets.Disclosure,
    LiveUi.Widgets.PresenceDot
  ]

  @spec modules() :: [module()]
  def modules, do: @modules
end
