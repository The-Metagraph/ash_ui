defmodule UnifiedIUR.Widgets.FoundationalTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Container
  alias UnifiedIUR.Element
  alias UnifiedIUR.Interaction
  alias UnifiedIUR.Style
  alias UnifiedIUR.Widgets.Foundational

  test "builds content-bearing visual widgets with canonical metadata and accessibility hooks" do
    title =
      Foundational.text("Unified IUR",
        id: "hero-title",
        description: "Hero title",
        annotations: [source: "phase-2"],
        tags: [:hero],
        accessibility: [label: "Hero title text"],
        style_refs: [:headline],
        variant: :hero
      )

    icon =
      Foundational.icon(:sparkles,
        id: "hero-icon",
        set: :system,
        fallback_text: "*",
        accessibility_hidden?: true
      )

    image =
      Foundational.image("asset://hero.png",
        id: "hero-image",
        alt_text: "Illustrated hero",
        media_type: "image/png",
        fit: :cover,
        accessibility: [label: "Hero illustration"]
      )

    badge =
      Foundational.badge("Live",
        id: "runtime-badge",
        icon: :sparkles,
        icon_set: :system,
        style_refs: [:badge]
      )

    hero =
      Foundational.hero(
        [
          {:supporting, Foundational.text("Semantic widgets stay semantic.", id: "hero-copy")},
          {:actions, Foundational.button("Explore", id: "hero-action")}
        ],
        id: "docs-hero",
        eyebrow: "UnifiedUi",
        title: "Ship richer dashboards",
        message: "Author semantic structure once and lower it into IUR."
      )

    assert %Element{
             id: "hero-title",
             kind: :text,
             metadata: %{
               description: "Hero title",
               annotations: %{source: "phase-2"},
               tags: [:hero]
             },
             attributes: %{
               content: %{text: "Unified IUR"},
               accessibility: %{label: "Hero title text"},
               theme: %{
                 component: :text,
                 token_refs: [%{kind: :token_ref, path: [:headline]}],
                 variant: :hero
               }
             }
           } = title

    assert %Element{
             id: "hero-icon",
             kind: :icon,
             attributes: %{
               icon: %{name: :sparkles, set: :system, fallback_text: "*"},
               accessibility: %{hidden?: true}
             }
           } = icon

    assert %Element{
             id: "hero-image",
             kind: :image,
             attributes: %{
               image: %{
                 source: "asset://hero.png",
                 media_type: "image/png",
                 alt_text: "Illustrated hero",
                 fit: :cover
               },
               accessibility: %{label: "Hero illustration"}
             }
           } = image

    assert %Element{
             id: "runtime-badge",
             kind: :badge,
             attributes: %{
               content: %{text: "Live"},
               badge: %{icon: :sparkles, icon_set: :system, presentation: :pill},
               theme: %{component: :badge}
             }
           } = badge

    assert %Element{
             id: "docs-hero",
             kind: :hero,
             children: [supporting, actions],
             attributes: %{
               hero: %{
                 eyebrow: "UnifiedUi",
                 title: "Ship richer dashboards",
                 message: "Author semantic structure once and lower it into IUR."
               }
             }
           } = hero

    assert supporting.slot == :supporting
    assert actions.slot == :actions
  end

  test "builds actionable foundational widgets with state, emphasis, and style hooks" do
    button =
      Foundational.button("Save",
        id: "save-button",
        action: [intent: :save],
        emphasis: :strong,
        disabled?: false,
        style_refs: [:primary_button],
        tone: :accent
      )

    link =
      Foundational.link("Docs", "https://specled.dev/home",
        id: "docs-link",
        external?: true,
        current?: true,
        emphasis: :subtle
      )

    separator =
      Foundational.separator(
        id: "section-divider",
        orientation: :vertical,
        decorative?: false,
        emphasis: :muted
      )

    spacer =
      Foundational.spacer(id: "toolbar-gap", size: :lg, grow: 1, min: 2)

    assert %Element{
             kind: :button,
             attributes: %{
               content: %{text: "Save"},
               state: %{disabled?: false, emphasis: :strong},
               style: %Style{emphasis: %{tone: :accent}},
               theme: %{
                 component: :button,
                 token_refs: [%{kind: :token_ref, path: [:primary_button]}]
               },
               interactions: [%Interaction{family: :click, intent: :save}]
             }
           } = button

    assert %Element{
             kind: :link,
             attributes: %{
               content: %{text: "Docs"},
               link: %{target: "https://specled.dev/home", external?: true, target_kind: :uri},
               state: %{current?: true, emphasis: :subtle},
               interactions: [%Interaction{family: :navigation, intent: :follow_link}]
             }
           } = link

    assert %Element{
             kind: :separator,
             attributes: %{
               separator: %{orientation: :vertical, decorative?: false},
               state: %{emphasis: :muted}
             }
           } = separator

    assert %Element{
             kind: :spacer,
             attributes: %{spacer: %{size: :lg, grow: 1, min: 2}}
           } = spacer
  end

  test "builds foundational content containers with stable nested child slots" do
    title = Foundational.label("Settings", id: "settings-label")
    body = Foundational.text("Manage your preferences.", id: "settings-copy")
    cta = Foundational.button("Continue", id: "continue-button")

    container =
      Container.content(
        [
          {:header, title},
          {:content, body},
          {:footer, cta}
        ],
        id: "settings-content",
        role: :article,
        presentation: :surface,
        accessibility: [label: "Settings content"]
      )

    assert %Element{
             id: "settings-content",
             kind: :content,
             children: [header, content, footer],
             attributes: %{
               container: %{role: :article, presentation: :surface},
               accessibility: %{label: "Settings content"}
             }
           } = container

    assert header.slot == :header
    assert content.slot == :content
    assert footer.slot == :footer
    assert header.element.id == "settings-label"
    assert content.element.id == "settings-copy"
    assert footer.element.id == "continue-button"
  end
end
