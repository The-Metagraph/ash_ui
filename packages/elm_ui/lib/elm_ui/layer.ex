defmodule ElmUi.Layer do
  @moduledoc """
  Package-facing entrypoint for direct-use overlay and layered composition
  constructs in `elm_ui`.
  """

  alias ElmUi.Widgets.Layered

  @type responsibility ::
          :layer_surface
          | :overlay_surface
          | :modal_surface
          | :dismissal_surface

  @spec responsibilities() :: [responsibility()]
  def responsibilities do
    [:layer_surface, :overlay_surface, :modal_surface, :dismissal_surface]
  end

  @spec modules() :: [module()]
  def modules, do: [Layered]

  @spec kinds() :: [atom()]
  def kinds, do: Layered.kinds()

  defdelegate overlay(id, base, layers, opts \\ []), to: Layered
  defdelegate dialog(id, content, opts \\ []), to: Layered
  defdelegate toast(id, content, opts \\ []), to: Layered
  defdelegate alert_dialog(id, content, opts \\ []), to: Layered
  defdelegate context_menu(id, items, opts \\ []), to: Layered
end
