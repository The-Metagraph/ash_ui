defmodule DesktopUi.Runtime.Poller do
  @moduledoc """
  Event polling scaffold for the shared SDL3 runtime loop.
  """

  @spec scaffold() :: map()
  def scaffold do
    %{
      status: :ready,
      source: :sdl_event_queue,
      last_poll: nil
    }
  end
end
