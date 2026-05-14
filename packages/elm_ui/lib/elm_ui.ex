defmodule ElmUi do
  @moduledoc """
  Package entrypoint for the `elm_ui` runtime scaffold.
  """

  alias ElmUi.{
    Continuity,
    Examples,
    Export,
    Frontend,
    Info,
    Inspect,
    Inspection,
    Layer,
    Layout,
    Reference,
    Renderer,
    Runtime,
    Server,
    Signals,
    Style,
    Theme,
    Tooling,
    Transport,
    Validate,
    Widgets
  }

  @type package_area ::
          :widgets
          | :layout
          | :layer
          | :runtime
          | :renderer
          | :signals
          | :transport
          | :style
          | :theme
          | :inspection
          | :tooling

  @spec package_areas() :: [package_area()]
  def package_areas do
    [
      :widgets,
      :layout,
      :layer,
      :runtime,
      :renderer,
      :signals,
      :transport,
      :style,
      :theme,
      :inspection,
      :tooling
    ]
  end

  @spec widgets() :: module()
  def widgets, do: Widgets

  @spec layout() :: module()
  def layout, do: Layout

  @spec layer() :: module()
  def layer, do: Layer

  @spec server() :: module()
  def server, do: Server

  @spec frontend() :: module()
  def frontend, do: Frontend

  @spec runtime() :: module()
  def runtime, do: Runtime

  @spec renderer() :: module()
  def renderer, do: Renderer

  @spec signals() :: module()
  def signals, do: Signals

  @spec transport() :: module()
  def transport, do: Transport

  @spec style() :: module()
  def style, do: Style

  @spec theme() :: module()
  def theme, do: Theme

  @spec inspection() :: module()
  def inspection, do: Inspection

  @spec inspect() :: module()
  def inspect, do: Inspect

  @spec export() :: module()
  def export, do: Export

  @spec continuity() :: module()
  def continuity, do: Continuity

  @spec validate() :: module()
  def validate, do: Validate

  @spec tooling() :: module()
  def tooling, do: Tooling

  @spec examples() :: module()
  def examples, do: Examples

  @spec reference() :: map()
  def reference, do: Reference.package_reference()

  @spec info() :: map()
  def info, do: Info.package_summary()
end
