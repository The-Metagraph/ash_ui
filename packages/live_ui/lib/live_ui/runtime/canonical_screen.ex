defmodule LiveUi.Runtime.CanonicalScreen do
  @moduledoc """
  Shared runtime screen wrapper for canonical `UnifiedIUR` rendering.
  """

  use LiveUi.Screen, id: :canonical_screen, title: "Canonical Screen"

  @impl true
  def metadata do
    %{
      kind: :canonical_screen,
      server_authoritative?: true,
      browser_bridge?: false,
      renderer_driven?: true
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <LiveUi.Renderer.render element={@iur} runtime_state={@runtime_state} event_target={@event_target} />
    """
  end
end
