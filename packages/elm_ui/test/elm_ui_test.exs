defmodule ElmUiTest do
  use ExUnit.Case, async: true

  test "package reference exposes split runtime and renderer areas" do
    assert [
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
           ] =
             ElmUi.package_areas()

    assert %{
             package: ElmUi,
             widgets: %{families: families},
             layout: %{kinds: layout_kinds},
             layer: %{kinds: layer_kinds},
             signals: %{families: signal_families},
             runtime: %{capabilities: runtime_capabilities},
             transport: %{modes: [:native_local, :canonical_boundary]},
             style: %{hooks: style_hooks},
             theme: %{catalog: theme_catalog},
             inspection: %{helpers: inspection_helpers},
             documentation: %{guides: guides},
             examples: %{native_ids: native_ids}
           } = ElmUi.reference()

    assert :content in families
    assert :viewport in layout_kinds
    assert :dialog in layer_kinds
    assert :command in signal_families
    assert :native_mount in runtime_capabilities
    assert :theme_tokens in style_hooks
    assert :default in theme_catalog
    assert :runtime_snapshot in inspection_helpers
    assert "guides/styling_and_inspection.md" in guides
    assert :native_styling in native_ids
  end

  test "package summary reports package identity" do
    assert %{
             package: :elm_ui,
             namespace: ElmUi,
             theme: %{default: :default},
             inspection: %{continuity_seams: continuity_seams},
             examples: %{workflows: workflows},
             validation: %{release_readiness: :pass, documentation_surface: :pass},
             documentation: %{guides: guides}
           } = ElmUi.info()

    assert :server_style_resolution in continuity_seams
    assert :styling in workflows
    assert "guides/styling_and_inspection.md" in guides
  end

  test "package exposes maintained native and canonical examples" do
    assert %{native: native, canonical: canonical} = ElmUi.Examples.comparison_examples()
    assert native.title == "Native Counter"
    assert canonical.kind == :text
  end
end
