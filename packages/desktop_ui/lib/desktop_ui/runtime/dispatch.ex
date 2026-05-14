defmodule DesktopUi.Runtime.Dispatch do
  @moduledoc """
  Input dispatch scaffold for the shared SDL3 runtime loop.
  """

  @spec scaffold() :: map()
  def scaffold do
    %{
      status: :ready,
      families: DesktopUi.Transport.input_families(),
      route_modes: [:local_runtime, :canonical_boundary],
      boundary_mode: :canonical_boundary_ready
    }
  end
end
