defmodule ElmUi.Server do
  @moduledoc """
  Package-facing Phoenix-side runtime entrypoints.
  """

  @spec runtime() :: module()
  def runtime, do: ElmUi.ServerRuntime

  @spec modules() :: [module()]
  def modules, do: ElmUi.ServerRuntime.modules()
end
