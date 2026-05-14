defmodule ElmUi.Layout do
  @moduledoc """
  Package-facing entrypoint for direct-use layout and display-system constructs
  in `elm_ui`.
  """

  alias ElmUi.Widgets.Layout, as: NativeLayout

  @type responsibility ::
          :display_system_surface
          | :layout_surface
          | :viewport_surface
          | :split_surface

  @spec responsibilities() :: [responsibility()]
  def responsibilities do
    [:display_system_surface, :layout_surface, :viewport_surface, :split_surface]
  end

  @spec modules() :: [module()]
  def modules, do: [NativeLayout]

  @spec kinds() :: [atom()]
  def kinds, do: NativeLayout.kinds()

  defdelegate stack(id, children, opts \\ []), to: NativeLayout
  defdelegate panel(id, title, children, opts \\ []), to: NativeLayout
  defdelegate row(id, children, opts \\ []), to: NativeLayout
  defdelegate column(id, children, opts \\ []), to: NativeLayout
  defdelegate grid(id, children, opts \\ []), to: NativeLayout
  defdelegate viewport(id, content, opts \\ []), to: NativeLayout
  defdelegate scroll_bar(id, opts \\ []), to: NativeLayout
  defdelegate split_pane(id, primary, secondary, opts \\ []), to: NativeLayout
end
