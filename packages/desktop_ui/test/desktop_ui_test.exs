defmodule DesktopUiTest do
  use ExUnit.Case, async: true

  test "package exposes phase one scaffold entrypoints" do
    assert DesktopUi.widgets() == DesktopUi.Widgets
    assert DesktopUi.widget() == DesktopUi.Widget
    assert DesktopUi.runtime() == DesktopUi.Runtime
    assert DesktopUi.platform() == DesktopUi.Platform
    assert DesktopUi.sdl3() == DesktopUi.Sdl3
    assert DesktopUi.layout() == DesktopUi.Layout
    assert DesktopUi.layer() == DesktopUi.Layer
    assert DesktopUi.renderer() == DesktopUi.Renderer
    assert DesktopUi.transport() == DesktopUi.Transport
    assert DesktopUi.style() == DesktopUi.Style
    assert DesktopUi.theme() == DesktopUi.Theme
    assert DesktopUi.continuity() == DesktopUi.Continuity
    assert DesktopUi.validate() == DesktopUi.Validate
    assert DesktopUi.artifacts() == DesktopUi.Artifacts
    assert DesktopUi.tooling() == DesktopUi.Tooling
    assert DesktopUi.reference().package == DesktopUi
    assert DesktopUi.info().package == :desktop_ui
  end

  test "mix project keeps desktop runtime policy explicit" do
    assert DesktopUi.MixProject.project()[:app] == :desktop_ui
    assert DesktopUi.MixProject.sdl_dependency_policy().foundation == :sdl3
    assert DesktopUi.MixProject.sdl_dependency_policy().binding == :sdl
    refute Keyword.has_key?(DesktopUi.MixProject.application(), :mod)
  end
end
