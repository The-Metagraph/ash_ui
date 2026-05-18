defmodule UnifiedUi.ContentIdentityComponentsTest do
  use ExUnit.Case, async: true

  alias Spark.Dsl.Extension
  alias UnifiedUi.Dsl.Node
  alias UnifiedUi.Dsl.Verifiers.ValidateWidgetComponents

  defmodule ContentIdentityScreen do
    use UnifiedUi.Dsl

    identity do
      id(:content_identity_screen)
      authored_ref([:examples, :content_identity_screen])
    end

    composition do
      root(:content_identity_root)
      mode(:screen)

      inline_rich_text_heading :headline do
        level(:h2)

        segments([
          %{type: :text, value: "Canonical widgets"},
          %{type: :emphasis, value: " across runtimes"}
        ])
      end

      kicker :eyebrow do
        items(["Operator surface", "Workspace"])
        separator("·")
      end

      avatar :operator_avatar do
        initials("PC")
        image_source("/images/pascal.png")
        size(:large)
        shape(:round)
        accessibility_label("Pascal Charbonneau")
      end

      presence_dot :operator_presence do
        state(:active)
        size(:small)
        accessibility_label("Active")
      end

      disclosure :advanced_options do
        summary("Advanced options")
        open?(true)

        text :advanced_copy do
          value("Additional runtime settings")
        end
      end
    end
  end

  test "registers authored content identity component kinds" do
    assert UnifiedUi.Widgets.content_identity_component_kinds() == [
             :inline_rich_text_heading,
             :disclosure,
             :kicker,
             :avatar,
             :presence_dot
           ]

    assert :inline_rich_text_heading in UnifiedUi.Widgets.kinds()
    assert :disclosure in UnifiedUi.Widgets.kinds()
  end

  test "stores content identity components in the composition tree" do
    [heading, kicker, avatar, presence, disclosure] =
      Extension.get_entities(ContentIdentityScreen, [:composition])

    assert {heading.family, heading.kind, heading.level} ==
             {:content_identity_and_disclosure, :inline_rich_text_heading, :h2}

    assert Enum.map(heading.segments, & &1.type) == [:text, :emphasis]

    assert {kicker.family, kicker.kind, kicker.separator} ==
             {:content_identity_and_disclosure, :kicker, "·"}

    assert {avatar.kind, avatar.initials, avatar.image_source, avatar.shape} ==
             {:avatar, "PC", "/images/pascal.png", :round}

    assert {presence.kind, presence.state, presence.size} == {:presence_dot, :active, :small}
    assert {disclosure.kind, disclosure.open?} == {:disclosure, true}
    assert Enum.map(disclosure.children, & &1.kind) == [:text]
  end

  test "summarizes content identity components without a renderer runtime" do
    assert UnifiedUi.Info.composition_summary(ContentIdentityScreen) == [
             %{
               id: :headline,
               family: :content_identity_and_disclosure,
               kind: :inline_rich_text_heading,
               level: :h2,
               segments: [
                 %{type: :text, value: "Canonical widgets"},
                 %{type: :emphasis, value: " across runtimes"}
               ]
             },
             %{
               id: :eyebrow,
               family: :content_identity_and_disclosure,
               kind: :kicker,
               items: ["Operator surface", "Workspace"],
               separator: "·"
             },
             %{
               id: :operator_avatar,
               family: :content_identity_and_disclosure,
               kind: :avatar,
               image_source: "/images/pascal.png",
               initials: "PC",
               shape: :round
             },
             %{
               id: :operator_presence,
               family: :content_identity_and_disclosure,
               kind: :presence_dot,
               state: :active
             },
             %{
               id: :advanced_options,
               family: :content_identity_and_disclosure,
               kind: :disclosure,
               open?: true,
               summary: "Advanced options",
               children: [
                 %{
                   id: :advanced_copy,
                   family: :foundational,
                   kind: :text,
                   role: :text,
                   value: "Additional runtime settings"
                 }
               ]
             }
           ]
  end

  test "tooling links the new family to the widget component specs" do
    {:ok, report} = UnifiedUi.Tooling.inspect_module(ContentIdentityScreen)

    assert :content_identity_and_disclosure in report.construct_families

    assert ".spec/specs/unified-ui/widget_components.spec.md" in report.related_specs
  end

  test "rejects malformed rich heading segments with an actionable diagnostic" do
    assert {:error, [:composition, :inline_rich_text_heading, :headline], message} =
             ValidateWidgetComponents.validate_node(%Node{
               kind: :inline_rich_text_heading,
               id: :headline,
               segments: [%{type: :delete, value: "Wrong segment"}]
             })

    assert message =~ "segments must be a non-empty list"
  end

  test "rejects malformed kicker items with an actionable diagnostic" do
    assert {:error, [:composition, :kicker, :bad_kicker], message} =
             ValidateWidgetComponents.validate_node(%Node{
               kind: :kicker,
               id: :bad_kicker,
               items: ["Valid", :invalid]
             })

    assert message == "kicker :bad_kicker items must be a list of strings"
  end
end
