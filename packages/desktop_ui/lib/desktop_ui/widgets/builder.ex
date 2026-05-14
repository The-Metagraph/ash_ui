defmodule DesktopUi.Widgets.Builder do
  @moduledoc """
  Builder helpers for direct-native `desktop_ui` widgets.
  """

  alias DesktopUi.Widget

  @spec window(String.t() | atom(), String.t(), [Widget.t()], keyword()) :: Widget.t()
  def window(id, title, children \\ [], opts \\ []) do
    Widget.new(:window,
      id: id,
      metadata: %{focusable: true, window_role: Keyword.get(opts, :window_role, :primary)},
      attributes: %{window_title: title},
      styles: Map.new(Keyword.get(opts, :styles, [])),
      children: children
    )
  end

  @spec dialog(String.t() | atom(), String.t(), [Widget.t()], keyword()) :: Widget.t()
  def dialog(id, title, children \\ [], opts \\ []) do
    Widget.new(:dialog,
      id: id,
      metadata: %{
        focusable: true,
        window_role: :dialog,
        overlay_role: :dialog,
        overlay_lifecycle: Keyword.get(opts, :overlay_lifecycle, :managed)
      },
      state: %{open: Keyword.get(opts, :open, true), phase: Keyword.get(opts, :phase, :active)},
      attributes: %{window_title: title},
      styles: Map.new(Keyword.get(opts, :styles, [])),
      children: children
    )
  end

  @spec column(String.t() | atom(), [Widget.t()], keyword()) :: Widget.t()
  def column(id, children \\ [], opts \\ []) do
    Widget.new(:column,
      id: id,
      metadata: %{focusable: false},
      attributes: %{gap: Keyword.get(opts, :gap, 16)},
      styles: Map.new(Keyword.get(opts, :styles, [])),
      children: children
    )
  end

  @spec row(String.t() | atom(), [Widget.t()], keyword()) :: Widget.t()
  def row(id, children \\ [], opts \\ []) do
    Widget.new(:row,
      id: id,
      metadata: %{focusable: false},
      attributes: %{gap: Keyword.get(opts, :gap, 12)},
      styles: Map.new(Keyword.get(opts, :styles, [])),
      children: children
    )
  end

  @spec stack(String.t() | atom(), [Widget.t()], keyword()) :: Widget.t()
  def stack(id, children \\ [], opts \\ []) do
    Widget.new(:stack,
      id: id,
      metadata: %{focusable: false},
      attributes: %{align: Keyword.get(opts, :align, :stretch)},
      styles: Map.new(Keyword.get(opts, :styles, [])),
      children: children
    )
  end

  @spec content(String.t() | atom(), [Widget.t()], keyword()) :: Widget.t()
  def content(id, children \\ [], opts \\ []) do
    DesktopUi.Widgets.Foundational.content(id, children, opts)
  end

  @spec text(String.t() | atom(), String.t(), keyword()) :: Widget.t()
  def text(id, content, opts \\ []) do
    DesktopUi.Widgets.Foundational.text(id, content, opts)
  end

  @spec button(String.t() | atom(), String.t(), keyword()) :: Widget.t()
  def button(id, label, opts \\ []) do
    DesktopUi.Widgets.Foundational.button(id, label, opts)
  end

  @spec text_input(String.t() | atom(), keyword()) :: Widget.t()
  def text_input(id, opts \\ []) do
    DesktopUi.Widgets.Input.text_input(id, opts)
  end

  @spec menu(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def menu(id, items, opts \\ []) do
    DesktopUi.Widgets.Navigation.menu(id, items, opts)
  end

  @spec status(String.t() | atom(), String.t(), keyword()) :: Widget.t()
  def status(id, label, opts \\ []) do
    Widget.new(:status,
      id: id,
      metadata: %{focusable: false},
      attributes: %{label: label},
      styles: Map.new(Keyword.get(opts, :styles, []))
    )
  end
end
