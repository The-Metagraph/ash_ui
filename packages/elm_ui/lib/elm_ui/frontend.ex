defmodule ElmUi.Frontend do
  @moduledoc """
  Package-facing Elm-side runtime entrypoints.
  """

  @spec runtime() :: module()
  def runtime, do: ElmUi.FrontendRuntime

  @spec modules() :: [module()]
  def modules, do: ElmUi.FrontendRuntime.modules()
end
