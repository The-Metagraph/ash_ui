defmodule DesktopUi.Platform.Adapter do
  @moduledoc """
  Behaviour for platform adapters that plug into the shared SDL3 runtime.
  """

  @callback summary() :: map()
  @callback integration_profile() :: map()
  @callback capabilities() :: [atom()]
  @callback callbacks() :: [atom()]
end
