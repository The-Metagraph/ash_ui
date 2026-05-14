defmodule ElmUi.StyleRealizationTest do
  use ExUnit.Case, async: true

  alias ElmUi.FrontendRuntime
  alias ElmUi.FrontendRuntime.StyleRealization
  alias ElmUi.ServerRuntime.StyleResolver

  test "server-side style resolution merges theme defaults, tokens, and active state variants" do
    widget =
      ElmUi.Widgets.text_input("query-input",
        value: "Pascal",
        focused: true,
        style_hooks: [:state_variants, :theme_tokens],
        theme_tokens: %{surface: [:surface, :default]},
        state_variants: %{focused: %{border: :focus_ring}}
      )

    resolution = StyleResolver.resolve(widget, theme: :midnight)

    assert resolution.theme == :midnight
    assert resolution.token_refs.surface == [:surface, :default]
    assert resolution.active_states == [:focused]
    assert resolution.resolved.variant == :field
    assert resolution.resolved.background == :panel
    assert resolution.resolved.border == :focus_ring
    assert resolution.resolved.surface == :panel
    assert resolution.diagnostics == []
  end

  test "server payload and frontend realization keep resolved style meaning deterministic" do
    screen =
      ElmUi.Widgets.screen(
        "styled-surface",
        "Styled Surface",
        [
          ElmUi.Widgets.button("save-button", "Save",
            variant: :primary,
            style_hooks: [:theme_tokens],
            theme_tokens: %{button: [:button, :primary]}
          )
        ],
        theme: :midnight
      )

    assert {:ok, state} = ElmUi.Runtime.mount_native_screen(screen)

    payload = ElmUi.ServerRuntime.frontend_payload(state)
    server_button = find_node(payload.tree, "save-button")

    assert server_button.theme.id == :midnight
    assert server_button.resolved_styles.variant == :primary
    assert server_button.resolved_styles.background == :accent_tint
    assert server_button.diagnostics.style_diagnostics == []

    assert {:ok, model} = ElmUi.Runtime.hydrate_frontend(state)
    frontend_button = find_node(model.tree, "save-button")

    assert frontend_button.styles.authored.variant == :primary
    assert frontend_button.styles.resolved.background == :accent_tint
    assert "theme-midnight" in frontend_button.browser.style.class_tokens
    assert "variant-primary" in frontend_button.browser.style.class_tokens
    assert frontend_button.browser.style.transitions.feedback?

    assert {:ok, focused_model} =
             FrontendRuntime.put_local_state(model, :focused_id, "save-button")

    focused_button = find_node(focused_model.tree, "save-button")

    assert "is-focused" in focused_button.browser.style.class_tokens
    assert focused_button.browser.style.transitions.focus_ring?

    assert StyleRealization.realize(server_button, %{focused_id: "save-button", editing_ids: []}) ==
             focused_button.browser.style
  end

  test "style diagnostics surface unresolved tokens, incompatible combinations, and invalid state wiring" do
    unresolved_token =
      ElmUi.Widgets.button("missing-token-button", "Broken",
        style_hooks: [:theme_tokens],
        theme_tokens: %{missing: [:button, :ghost]}
      )

    hidden_emphasis =
      ElmUi.Widgets.text("hidden-alert", "Hidden",
        visibility: :hidden,
        emphasis: :strong
      )

    invalid_state_variant =
      ElmUi.Widgets.text_input("query-input",
        value: "",
        focused: true,
        style_hooks: [:state_variants]
      )

    assert [%{reason: :unresolved_theme_token}] =
             StyleResolver.resolve(unresolved_token, theme: :default).diagnostics

    assert [
             %{
               reason: :incompatible_style_combination,
               detail: :visibility_conflicts_with_emphasis
             }
           ] =
             StyleResolver.resolve(hidden_emphasis, theme: :default).diagnostics

    assert [%{reason: :invalid_state_variant_wiring, states: [:focused]}] =
             StyleResolver.resolve(invalid_state_variant, theme: :default).diagnostics
  end

  defp find_node(node, id) when is_map(node) do
    if node.id == id do
      node
    else
      node.slots
      |> Enum.flat_map(& &1.children)
      |> Enum.find_value(&find_node(&1, id))
    end
  end

  defp find_node(nil, _id), do: nil
end
