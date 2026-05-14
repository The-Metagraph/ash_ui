defmodule DesktopUi.StyleTest do
  use ExUnit.Case, async: true

  alias DesktopUi.Runtime

  test "style primitives and theme catalog expose shared native styling surface" do
    assert :focus_ring in DesktopUi.Style.primitives().colors
    assert :semantic_role in DesktopUi.Style.widget_style_hooks()
    assert DesktopUi.Style.validation_state().direct_native_surface == :ready

    assert DesktopUi.Theme.default_theme().id == :desktop_default
    assert :desktop_default in DesktopUi.Theme.catalog_ids()
    assert :high_contrast in DesktopUi.Theme.catalog_ids()
    assert DesktopUi.Theme.validation_state().shared_style_model == :ready
    assert DesktopUi.Theme.continuity_rules().shared_native_and_canonical_model
  end

  test "runtime resolves effective styles through shared theme inheritance" do
    screen = %{
      id: "styled-review",
      title: "Styled Review",
      root:
        DesktopUi.Widgets.window(
          "styled-window",
          "Styled Review",
          [
            DesktopUi.Widgets.text("hero-copy", "Styled Review",
              styles: [
                theme_tokens: %{headline: [:text, :hero]}
              ]
            ),
            DesktopUi.Widgets.button("launch-button", "Launch",
              styles: [
                theme_tokens: %{primary: [:button, :primary]},
                state_variants: %{focused: %{border: :focus_ring}}
              ]
            )
            |> then(fn button -> %{button | state: Map.put(button.state, :focused, true)} end)
          ],
          styles: [
            theme: :desktop_default,
            theme_tokens: %{chrome: [:surface, :panel]}
          ]
        )
    }

    assert {:ok, state} = Runtime.mount_native_screen(screen, platform_target: :linux)

    assert state.screen.metadata.theme == :desktop_default
    assert state.realization.theme == :desktop_default
    assert state.realization.style_contract.shared_model
    assert state.realization.diagnostics.style_resolution == :ready
    assert state.realization.diagnostics.style_warnings == []

    assert state.realization.style_index["styled-window"].border == :single
    assert state.realization.style_index["styled-window"].theme == :desktop_default
    assert :bold in state.realization.style_index["hero-copy"].attrs
    assert state.realization.style_index["hero-copy"].semantic_role == :title
    assert state.realization.style_index["launch-button"].variant == :accented
    assert state.realization.style_index["launch-button"].border == :focus_ring
    assert state.realization.style_index["launch-button"].semantic_role == :primary_action

    assert Enum.any?(state.realization.cell_surface, fn cell ->
             cell.widget_id == "launch-button" and cell.styles.variant == :accented
           end)
  end
end
