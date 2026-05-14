defmodule LiveUi.Layer do
  @moduledoc """
  Package-facing reference surface for overlay and layering primitives.
  """

  @spec modules() :: [module()]
  def modules do
    LiveUi.Widgets.Overlay.modules()
  end

  @spec overlay_kinds() :: [atom()]
  def overlay_kinds do
    [:overlay, :dialog, :alert_dialog, :context_menu, :toast]
  end

  @spec visibility_states() :: [atom()]
  def visibility_states do
    [:hidden, :visible]
  end
end
