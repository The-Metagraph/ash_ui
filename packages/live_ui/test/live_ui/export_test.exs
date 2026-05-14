defmodule LiveUi.ExportTest do
  use ExUnit.Case, async: true

  test "export can render stable metadata and html for maintained examples" do
    assert {:ok, metadata} = LiveUi.Export.example(:button, :metadata)
    assert metadata =~ "button"
    assert metadata =~ "preview_id"

    assert {:ok, html} = LiveUi.Export.example(:table, :html)
    assert html =~ "data-live-ui-widget=\"table\""
    assert html =~ "data-live-ui-widget=\"screen-shell\""
  end

  test "export can print comparison and diagnostics output for paired examples" do
    assert {:ok, comparison} = LiveUi.Export.example(:button, :comparison)
    assert comparison =~ "button"
    assert comparison =~ "Button Canonical Review"
    assert comparison =~ "widgets_aligned?"
    assert comparison =~ "browser_style_aligned?"
    assert comparison =~ "browser_style"

    assert {:ok, diagnostics} = LiveUi.Export.example(:button, :diagnostics)
    assert diagnostics =~ "diagnostics"
    assert diagnostics =~ "Button Canonical Review"
    assert diagnostics =~ "native_browser_style"
  end

  test "export can print style-focused output and browser-style artifacts" do
    assert {:ok, style} = LiveUi.Export.example(:button, :style)
    assert style =~ "browser_style_nodes"
    assert style =~ "realized_entry_ids"

    assert {:ok, artifact} = LiveUi.Export.example(:button, :artifact)
    assert artifact =~ "browser_style_nodes"
    assert artifact =~ "html"
    assert artifact =~ "canonical"
  end
end
