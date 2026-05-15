defmodule LiveUi.RendererTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias UnifiedIUR.{Container, Element, Forms, Interaction, Layout}
  alias UnifiedIUR.Widgets.{Components, Foundational, Input, Navigation}

  test "renderer maps foundational canonical widgets and layouts into native components" do
    element =
      Container.box(
        [
          Layout.row([
            Foundational.text("Hello"),
            Foundational.button("Save")
          ]),
          Navigation.tabs(
            [
              %{id: "details", label: "Details", active?: true},
              %{id: "activity", label: "Activity"}
            ],
            active_item: "details"
          )
        ],
        id: "root-box"
      )

    html = render_component(&LiveUi.Renderer.render/1, %{element: element})

    assert html =~ "data-live-ui-widget=\"box\""
    assert html =~ "data-live-ui-widget=\"row\""
    assert html =~ "data-live-ui-widget=\"text\""
    assert html =~ "data-live-ui-widget=\"button\""
    assert html =~ "data-live-ui-widget=\"tabs\""
  end

  test "renderer maps canonical form constructs through native form and input surfaces" do
    element =
      Forms.form_builder(
        [
          Forms.field_group(
            [
              Forms.field(
                Input.text_input(name: "name", value: "Pascal", placeholder: "Name"),
                id: "name-field",
                name: "name",
                label: "Name"
              )
            ],
            legend: "Identity"
          )
        ],
        id: "profile-form"
      )

    html = render_component(&LiveUi.Renderer.render/1, %{element: element})

    assert html =~ "data-live-ui-widget=\"form-builder\""
    assert html =~ "data-live-ui-widget=\"field-group\""
    assert html =~ "data-live-ui-widget=\"field\""
    assert html =~ "data-live-ui-widget=\"text-input\""
    assert html =~ "Pascal"
  end

  test "renderer maps unread_badge canonical components into native badge markup" do
    element = Components.unread_badge(108, tone: :critical, id: "sidebar-unread")

    html = render_component(&LiveUi.Renderer.render/1, %{element: element})

    assert html =~ ~s(data-live-ui-widget="unread-badge")
    assert html =~ ~s(data-live-ui-tone="critical")
    assert html =~ ~s(aria-label="108 unread items")
    assert html =~ "99+"
  end

  test "renderer maps sidebar_item canonical components into native navigation markup" do
    element =
      Components.sidebar_item("build/phase-31.2",
        id: "build-sidebar-item",
        glyph: "◇",
        meta: "phase 31.2",
        state: :blocked,
        item_kind: :build,
        item_id: "phase-31.2",
        link_target: "/builds/phase-31.2",
        unread_count: 12
      )

    html = render_component(&LiveUi.Renderer.render/1, %{element: element})

    assert html =~ ~s(data-live-ui-widget="sidebar-item")
    assert html =~ ~s(data-live-ui-kind="build")
    assert html =~ ~s(data-live-ui-state="blocked")
    assert html =~ ~s(href="/builds/phase-31.2")
    assert html =~ "build/phase-31.2"
    assert html =~ "phase 31.2"
    assert html =~ ~s(data-live-ui-widget="unread-badge")
  end

  test "renderer maps sidebar_section canonical components into native grouping markup" do
    element =
      Components.sidebar_section(
        "Channels",
        [
          Components.sidebar_item("metagraph-team",
            glyph: "#",
            item_kind: :channel,
            item_id: "metagraph-team",
            action_intent: :open_channel
          )
        ],
        id: "channels-section",
        action_glyph: "+",
        action_label: "New channel",
        action_intent: :new_channel,
        interactions: [Interaction.click(intent: :new_channel)]
      )

    html =
      render_component(&LiveUi.Renderer.render/1, %{
        element: element,
        event_target: "#runtime-host"
      })

    assert html =~ ~s(data-live-ui-widget="sidebar-section")
    assert html =~ "Channels"
    assert html =~ ~s(aria-label="New channel")
    assert html =~ ~s(phx-click="canonical_interaction")
    assert html =~ ~s(phx-target="#runtime-host")
    assert html =~ ~s(data-live-ui-widget="sidebar-item")
  end

  test "renderer maps sidebar_shell canonical components into navigation shell markup" do
    element =
      Components.sidebar_shell(
        [
          Components.sidebar_section(
            "Channels",
            [
              Components.sidebar_item("metagraph-team",
                glyph: "#",
                item_kind: :channel,
                item_id: "metagraph-team",
                action_intent: :open_channel
              )
            ],
            action_glyph: "+",
            action_label: "New channel",
            action_intent: :new_channel
          )
        ],
        id: "primary-navigation",
        width: :wide,
        aria_label: "primary navigation"
      )

    html = render_component(&LiveUi.Renderer.render/1, %{element: element})

    assert html =~ ~s(data-live-ui-widget="sidebar-shell")
    assert html =~ ~s(data-live-ui-width="wide")
    assert html =~ ~s(aria-label="primary navigation")
    assert html =~ "live-ui-sidebar-shell-scroll"
    assert html =~ ~s(data-live-ui-widget="sidebar-section")
  end

  test "runtime can mount canonical unified_iur input through the shared screen host" do
    element =
      Layout.column([
        Foundational.label("Status"),
        Input.select(
          [
            %{value: "draft", label: "Draft"},
            %{value: "published", label: "Published", selected?: true}
          ],
          name: "status"
        )
      ])

    assert {:ok, runtime_state} = LiveUi.Runtime.mount_iur(element)

    html =
      render_component(LiveUi.Runtime.component(), id: "canonical", runtime_state: runtime_state)

    assert html =~ "data-live-ui-runtime=\"screen\""
    assert html =~ "data-live-ui-widget=\"column\""
    assert html =~ "data-live-ui-widget=\"label\""
    assert html =~ "data-live-ui-widget=\"select\""
  end

  test "renderer maps canonical accessibility metadata into native box semantics" do
    element =
      Element.new(:layout, :box,
        id: "accessible-box",
        attributes: %{
          accessibility: %{
            role: "region",
            label: "Signal lab outcome region",
            labelled_by: "outcome-title",
            described_by: "outcome-copy",
            live: "polite",
            atomic: true
          }
        },
        children: []
      )

    html = render_component(&LiveUi.Renderer.render/1, %{element: element})

    assert html =~ ~s(id="accessible-box")
    assert html =~ ~s(role="region")
    assert html =~ ~s(aria-label="Signal lab outcome region")
    assert html =~ ~s(aria-labelledby="outcome-title")
    assert html =~ ~s(aria-describedby="outcome-copy")
    assert html =~ ~s(aria-live="polite")
    assert html =~ ~s(aria-atomic="true")
  end

  test "renderer lowers canonical button interactions into LiveView click bindings when a string event target is present" do
    element =
      Foundational.button("Inspect",
        id: "inspect-button",
        interactions: [
          UnifiedIUR.Interaction.click(intent: :inspect_button, element_id: "inspect-button")
        ]
      )

    html =
      render_component(&LiveUi.Renderer.render/1, %{
        element: element,
        event_target: "#runtime-host"
      })

    assert html =~ ~s(phx-click="canonical_interaction")
    assert html =~ ~s(phx-target="#runtime-host")
    assert html =~ ~s(phx-value-widget="button")
    assert html =~ ~s(phx-value-element_id="inspect-button")
  end

  test "renderer lowers canonical input interactions into LiveView change bindings when a string event target is present" do
    element =
      Input.text_input(
        name: "draft_note",
        value: "review-ready",
        placeholder: "Draft",
        id: "draft-note-input",
        interactions: [
          UnifiedIUR.Interaction.change(intent: :draft_note, element_id: "draft-note-input")
        ]
      )

    html =
      render_component(&LiveUi.Renderer.render/1, %{
        element: element,
        event_target: "#runtime-host"
      })

    assert html =~ ~s(phx-change="canonical_interaction")
    assert html =~ ~s(phx-target="#runtime-host")
    assert html =~ ~s(name="widget" value="text_input")
    assert html =~ ~s(name="element_id" value="draft-note-input")
  end

  test "renderer lowers canonical form interactions into LiveView form bindings when an event target is present" do
    element =
      Forms.form_builder(
        [
          Forms.field(
            Input.text_input(name: "name", value: "Pascal"),
            id: "name-field",
            name: "name",
            label: "Name"
          )
        ],
        id: "profile-form",
        interactions: [
          UnifiedIUR.Interaction.change(intent: :review_form, element_id: "profile-form")
        ]
      )

    html =
      render_component(&LiveUi.Renderer.render/1, %{
        element: element,
        event_target: "#runtime-host"
      })

    assert html =~ ~s(phx-change="canonical_change_interaction")
    assert html =~ ~s(phx-target="#runtime-host")
    assert html =~ ~s(phx-value-widget="form_builder")
    assert html =~ ~s(phx-value-element_id="profile-form")
  end

  test "equivalent canonical inputs map deterministically into the same native structure" do
    left =
      Layout.row([
        Foundational.text("A"),
        Foundational.spacer(size: :sm),
        Foundational.link("Docs", "/docs")
      ])

    right =
      Layout.row([
        Foundational.text("A", %{}),
        Foundational.spacer(size: :sm, metadata: %{}),
        Foundational.link("Docs", "/docs", [])
      ])

    assert render_component(&LiveUi.Renderer.render/1, %{element: left}) ==
             render_component(&LiveUi.Renderer.render/1, %{element: right})
  end

  test "renderer lowers canonical button interactions into LiveView click bindings when an event target is present" do
    element =
      Foundational.button("Save",
        id: "save-button",
        interactions: [Interaction.click(intent: :save_profile, element_id: :save_button)]
      )

    html =
      render_component(&LiveUi.Renderer.render/1, %{
        element: element,
        event_target: %Phoenix.LiveComponent.CID{cid: 1}
      })

    assert html =~ ~s(data-live-ui-widget="button")
    assert html =~ ~s(phx-click="canonical_interaction")
    assert html =~ ~s(phx-target="1")
    assert html =~ ~s(phx-value-element_id="save-button")
    assert html =~ ~s(phx-value-widget="button")
  end

  test "renderer lowers canonical text input interactions into LiveView change bindings when an event target is present" do
    element =
      Input.text_input(
        id: "profile-name",
        name: "note",
        value: "",
        placeholder: "Type your note",
        interactions: [Interaction.change(intent: :draft_note, element_id: :profile_name)]
      )

    html =
      render_component(&LiveUi.Renderer.render/1, %{
        element: element,
        event_target: %Phoenix.LiveComponent.CID{cid: 1}
      })

    assert html =~ ~s(data-live-ui-widget="text-input")
    assert html =~ ~s(phx-input="canonical_interaction")
    assert html =~ ~s(phx-change="canonical_interaction")
    assert html =~ ~s(phx-target="1")
    assert html =~ ~s(data-live-ui-interaction-form="true")
    assert html =~ ~s(name="element_id" value="profile-name")
    assert html =~ ~s(name="widget" value="text_input")
  end
end
