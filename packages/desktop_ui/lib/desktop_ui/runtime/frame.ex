defmodule DesktopUi.Runtime.Frame do
  @moduledoc """
  Frame coordination scaffold for the shared SDL3 runtime loop.
  """

  @spec scaffold() :: map()
  def scaffold do
    %{
      status: :ready,
      cadence: :vsync_placeholder,
      present_mode: :shared_runtime
    }
  end
end
