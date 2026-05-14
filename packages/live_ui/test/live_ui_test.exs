defmodule LiveUiTest do
  use ExUnit.Case, async: true

  test "package reference exposes canonical areas" do
    assert [:widgets, :runtime, :renderer, :transport, :tooling, :styling] =
             LiveUi.package_areas()

    assert %{
             package: LiveUi,
             widgets: %{families: families},
             runtime: %{capabilities: runtime_capabilities},
             transport: %{modes: [:native_local, :canonical_boundary]}
           } = LiveUi.reference()

    assert :content in families
    assert :native_mount in runtime_capabilities
  end

  test "package exposes native screen namespace" do
    assert LiveUi.screen() == LiveUi.Screen
  end

  test "package exposes native forms namespace" do
    assert LiveUi.forms() == LiveUi.Forms
  end

  test "package exposes native layout namespace" do
    assert LiveUi.layout() == LiveUi.Layout
  end

  test "package exposes example namespace" do
    assert LiveUi.examples() == LiveUi.Examples
  end

  test "package exposes signal namespace" do
    assert LiveUi.signals() == LiveUi.Signals
  end

  test "package summary reports package identity" do
    assert %{package: :live_ui, namespace: LiveUi} = LiveUi.info()
  end
end
