defmodule LiveUi.Widgets.Overlay do
  @moduledoc """
  Reference surface for overlay-driven native widgets.
  """

  @modules [
    LiveUi.Widgets.OverlaySurface,
    LiveUi.Widgets.Dialog,
    LiveUi.Widgets.AlertDialog,
    LiveUi.Widgets.ContextMenu,
    LiveUi.Widgets.Toast,
    LiveUi.Widgets.AskSidebar,
    LiveUi.Widgets.ComposerInlineAsk
  ]

  @spec modules() :: [module()]
  def modules do
    @modules
  end
end
