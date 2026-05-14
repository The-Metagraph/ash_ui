defmodule ElmUi.StyleTest do
  use ExUnit.Case, async: true

  test "style primitives expose portable native styling categories" do
    primitives = ElmUi.Style.primitives()

    assert :display in primitives.typography
    assert :accent in primitives.color_roles
    assert :md in primitives.spacing
    assert :focus_ring in primitives.borders
    assert :scrim in primitives.backgrounds
    assert :hidden in primitives.visibility
    assert :intense in primitives.emphasis
    assert :theme_tokens in ElmUi.Style.portable_keys()
    assert :state_variants in ElmUi.Style.widget_style_hooks()
  end

  test "style normalization keeps only portable keys and normalizes state variants" do
    normalized =
      ElmUi.Style.normalize(
        tone: :accent,
        variant: :primary,
        background: :panel,
        hooks: ["tone", :theme_tokens],
        theme_tokens: %{button: [:button, :primary]},
        state_variants: %{
          "focused" => %{"border" => :focus_ring, "unknown" => :ignored},
          "loading" => %{visibility: :muted}
        },
        renderer_escape_hatch: "ignored"
      )

    assert normalized.tone == :accent
    assert normalized.variant == :primary
    assert normalized.hooks == [:tone, :theme_tokens]
    assert normalized.theme_tokens.button == [:button, :primary]
    assert normalized.state_variants.focused.border == :focus_ring
    assert normalized.state_variants.loading.visibility == :muted
    refute Map.has_key?(normalized, :renderer_escape_hatch)
  end

  test "theme catalog exposes defaults, palette roles, and token resolution" do
    assert [:default, :midnight] = ElmUi.Theme.catalog_ids() |> Enum.sort()
    assert :canvas in ElmUi.Theme.palette_roles()
    assert ElmUi.Theme.default_theme().id == :default
    assert ElmUi.Theme.runtime_contract().authoritative_server_theme

    assert {:ok, %{surface: :panel}} = ElmUi.Theme.resolve_token(:default, [:surface, :default])

    assert {:ok, %{variant: :primary, tone: :accent}} =
             ElmUi.Theme.resolve_token(:default, [:button, :primary])

    assert {:error, :unknown_token} = ElmUi.Theme.resolve_token(:default, [:missing, :token])
  end
end
