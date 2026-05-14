defmodule DesktopUi do
  @moduledoc """
  Package entrypoint for the `desktop_ui` runtime scaffold.
  """

  alias DesktopUi.{
    Artifacts,
    Continuity,
    Examples,
    Info,
    Inspection,
    Layer,
    Layout,
    Platform,
    Reference,
    Renderer,
    Runtime,
    Sdl3,
    Style,
    Theme,
    Tooling,
    Transport,
    Validate,
    Widget,
    Widgets
  }

  @type package_area ::
          :widgets
          | :runtime
          | :sdl3
          | :platform
          | :layout
          | :layer
          | :renderer
          | :transport
          | :style
          | :theme
          | :continuity
          | :validate
          | :artifacts
          | :examples
          | :inspection
          | :tooling

  @spec package_areas() :: [package_area()]
  def package_areas do
    [
      :widgets,
      :runtime,
      :sdl3,
      :platform,
      :layout,
      :layer,
      :renderer,
      :transport,
      :style,
      :theme,
      :continuity,
      :validate,
      :artifacts,
      :examples,
      :inspection,
      :tooling
    ]
  end

  @spec widgets() :: module()
  def widgets, do: Widgets

  @spec widget() :: module()
  def widget, do: Widget

  @spec runtime() :: module()
  def runtime, do: Runtime

  @spec platform() :: module()
  def platform, do: Platform

  @spec sdl3() :: module()
  def sdl3, do: Sdl3

  @spec layout() :: module()
  def layout, do: Layout

  @spec layer() :: module()
  def layer, do: Layer

  @spec renderer() :: module()
  def renderer, do: Renderer

  @spec transport() :: module()
  def transport, do: Transport

  @spec style() :: module()
  def style, do: Style

  @spec theme() :: module()
  def theme, do: Theme

  @spec continuity() :: module()
  def continuity, do: Continuity

  @spec validate() :: module()
  def validate, do: Validate

  @spec artifacts() :: module()
  def artifacts, do: Artifacts

  @spec examples() :: module()
  def examples, do: Examples

  @spec inspection() :: module()
  def inspection, do: Inspection

  @spec tooling() :: module()
  def tooling, do: Tooling

  @spec reference() :: map()
  def reference, do: Reference.package_reference()

  @spec info() :: map()
  def info, do: Info.package_summary()
end
