defmodule UnifiedIUR.StyleTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Style
  alias UnifiedIUR.Style.{Color, TextAttributes}

  test "builds named, indexed, and rgb color values" do
    assert %{mode: :named, name: :primary} = Color.new(:primary)
    assert %{mode: :indexed, index: 17} = Color.new({:indexed, 17})
    assert %{mode: :rgb, red: 12, green: 34, blue: 56} = Color.new({:rgb, 12, 34, 56})
  end

  test "normalizes and merges text emphasis flags" do
    left = TextAttributes.new(bold?: true, italic?: true)
    right = TextAttributes.new(%{"underline?" => true, "strikethrough?" => true})
    merged = TextAttributes.merge(left, right)

    assert %TextAttributes{
             bold?: true,
             italic?: true,
             underline?: true,
             strikethrough?: true
           } = merged
  end

  test "normalizes partial style values and supports merged style models" do
    base =
      Style.new(
        foreground: :primary,
        spacing: [padding: 2],
        alignment: [horizontal: :center],
        text: [bold?: true],
        visibility: [hidden?: false]
      )

    variant =
      Style.new(
        background: {:rgb, 20, 30, 40},
        border: [style: :solid],
        emphasis: [tone: :accent],
        state_variants: %{
          focused: %{border_color: {:indexed, 21}, text: [underline?: true]}
        }
      )

    merged = Style.merge(base, variant)

    assert %Style{
             foreground: %{mode: :named, name: :primary},
             background: %{mode: :rgb, red: 20, green: 30, blue: 40},
             spacing: %{padding: 2},
             alignment: %{horizontal: :center},
             border: %{style: :solid},
             emphasis: %{tone: :accent},
             text: %TextAttributes{bold?: true},
             state_variants: %{
               focused: %Style{
                 border_color: %{mode: :indexed, index: 21},
                 text: %TextAttributes{underline?: true}
               }
             }
           } = merged
  end

  test "adds and reads state variants deterministically" do
    style =
      Style.new(nil)
      |> Style.put_state_variant(:selected, %{
        foreground: :selected_fg,
        emphasis: %{tone: :selected}
      })

    assert %Style{
             foreground: %{mode: :named, name: :selected_fg},
             emphasis: %{tone: :selected}
           } = Style.state_variant(style, :selected)
  end
end
