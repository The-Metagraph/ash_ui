defmodule UnifiedUi.WidgetsTest do
  use ExUnit.Case, async: true

  alias Spark.Dsl.Extension

  defmodule FoundationalScreen do
    use UnifiedUi.Dsl

    identity do
      id(:foundational_screen)
      authored_ref([:examples, :foundational_screen])
    end

    composition do
      root(:foundational_root)
      mode(:screen)

      content :hero do
        summary("Hero content")

        text :headline do
          value("Welcome to UnifiedUi")
        end

        button :primary_action do
          label("Continue")
          action_intent(:continue)
        end

        spacer :section_gap do
          size(:lg)
        end
      end
    end
  end

  test "registers foundational widget kinds for package inspection" do
    assert UnifiedUi.Widgets.foundational_kinds() == [
             :text,
             :label,
             :icon,
             :image,
             :badge,
             :hero,
             :content,
             :button,
             :link,
             :separator,
             :spacer
           ]
  end

  test "stores foundational authored nodes in the composition section" do
    [hero] = Extension.get_entities(FoundationalScreen, [:composition])

    assert hero.family == :foundational
    assert hero.kind == :content
    assert hero.id == :hero
    assert Enum.map(hero.children, & &1.kind) == [:text, :button, :spacer]
  end

  test "summarizes foundational authored composition without a renderer runtime" do
    assert UnifiedUi.Info.composition_summary(FoundationalScreen) == [
             %{
               id: :hero,
               family: :foundational,
               kind: :content,
               role: :content,
               presentation: :body,
               summary: "Hero content",
               children: [
                 %{
                   id: :headline,
                   family: :foundational,
                   kind: :text,
                   role: :text,
                   value: "Welcome to UnifiedUi"
                 },
                 %{id: :primary_action, family: :foundational, kind: :button, label: "Continue"},
                 %{id: :section_gap, family: :foundational, kind: :spacer}
               ]
             }
           ]
  end
end
