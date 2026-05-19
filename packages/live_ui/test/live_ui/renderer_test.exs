defmodule LiveUi.RendererTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias UnifiedIUR.{Container, Element, Forms, Interaction, Layout}
  alias UnifiedIUR.Widgets.{Components, Feedback, Foundational, Input, Navigation}

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

  test "renderer maps confidence_indicator through the native feedback boundary" do
    element =
      Feedback.confidence_indicator(0.87,
        id: "confidence-score",
        label: "Match confidence",
        thresholds: %{warn: 0.5, pass: 0.8}
      )

    html = render_component(&LiveUi.Renderer.render/1, %{element: element})

    assert html =~ ~s(data-live-ui-widget="confidence-indicator")
    assert html =~ ~s(role="meter")
    assert html =~ ~s(aria-valuenow="87")
    assert html =~ ~s(data-confidence-band="pass")
    assert html =~ ~s(aria-label="Match confidence")
  end

  test "renderer maps canonical presence dot through the native component boundary" do
    element =
      Components.presence_dot(:do_not_disturb,
        id: "presence",
        accessibility_label: "Pascal is in do not disturb"
      )

    html = render_component(&LiveUi.Renderer.render/1, %{element: element})

    assert html =~ ~s(data-live-ui-widget-boundary="presence_dot")
    assert html =~ ~s(data-live-ui-widget="presence_dot")
    assert html =~ ~s(data-presence-state="do_not_disturb")
    assert html =~ ~s(aria-label="Pascal is in do not disturb")
  end

  test "renderer maps canonical disclosure through the native component boundary" do
    element =
      Components.disclosure(
        "Advanced options",
        [Foundational.text("Disclosure body", id: "disclosure-body")],
        id: "advanced-options",
        open?: true
      )

    html = render_component(&LiveUi.Renderer.render/1, %{element: element})

    assert html =~ ~s(data-live-ui-widget-boundary="disclosure")
    assert html =~ ~s(data-live-ui-widget="disclosure")
    assert html =~ ~s(id="advanced-options")
    assert html =~ "Advanced options"
    assert html =~ "Disclosure body"
    assert html =~ " open"
    refute html =~ "data-live-ui-unsupported-native-component"
  end

  test "renderer maps canonical segmented button group through the native component boundary" do
    element =
      Components.segmented_button_group(
        [
          %{value: :all, label: "All"},
          %{value: :open, label: "Open", disabled?: true},
          %{value: :closed, label: "Closed"}
        ],
        id: "status-filter",
        active_value: :all,
        selection_intent: :select_status,
        accessibility_label: "Status filter"
      )

    html =
      render_component(&LiveUi.Renderer.render/1, %{
        element: element,
        event_target: "#runtime-host"
      })

    assert html =~ ~s(data-live-ui-widget-boundary="segmented_button_group")
    assert html =~ ~s(data-live-ui-widget="segmented_button_group")
    assert html =~ ~s(role="radiogroup")
    assert html =~ ~s(aria-label="Status filter")
    assert html =~ "All"
    assert html =~ "Open"
    assert html =~ ~s(data-option-value="all")
    assert html =~ ~s(aria-checked="true")
    assert html =~ "is-selected"
    assert html =~ "disabled"
    assert html =~ ~s(phx-click="canonical_interaction")
    assert html =~ ~s(phx-target="#runtime-host")
    assert html =~ ~s(phx-value-widget="segmented_button_group")
    assert html =~ ~s(phx-value-element_id="status-filter")
    assert html =~ ~s(phx-value-value="closed")
    assert html =~ ~s(phx-value-selected_value="closed")
    assert html =~ ~s(phx-value-interaction=)
    refute html =~ "data-live-ui-unsupported-native-component"
  end

  test "renderer maps canonical context selector through the native navigation boundary" do
    element =
      Navigation.context_selector(
        id: "workspace-context",
        selector_id: "workspace-context",
        groups: [
          %{
            id: :workspace,
            label: "Workspace",
            items: [
              %{value: :all, label: "All workspaces"},
              %{value: :active, label: "Active workspace", disabled?: true}
            ]
          }
        ],
        selected_values: [:all],
        max_selections: :unlimited,
        open?: true,
        selection_intent: :select_context
      )

    html =
      render_component(&LiveUi.Renderer.render/1, %{
        element: element,
        event_target: "#runtime-host"
      })

    assert html =~ ~s(data-live-ui-widget-boundary="context_selector")
    assert html =~ ~s(data-live-ui-widget="context-selector")
    assert html =~ ~s(role="listbox")
    assert html =~ ~s(aria-multiselectable="true")
    assert html =~ "All workspaces"
    assert html =~ ~s(data-context-value="all")
    assert html =~ ~s(aria-selected="true")
    assert html =~ ~s(phx-click="canonical_interaction")
    assert html =~ ~s(phx-target="#runtime-host")
    assert html =~ ~s(phx-value-widget="context_selector")
    assert html =~ ~s(phx-value-element_id="workspace-context")
    assert html =~ ~s(phx-value-group_id="workspace")
    assert html =~ ~s(phx-value-selected_value="all")
    refute html =~ "data-live-ui-unsupported-native-component"
  end

  test "renderer preserves canonical decorative presence dot semantics" do
    element =
      Components.presence_dot(:active,
        id: "decorative-presence",
        decorative?: true
      )

    html = render_component(&LiveUi.Renderer.render/1, %{element: element})

    assert html =~ ~s(data-live-ui-widget-boundary="presence_dot")
    assert html =~ ~s(data-presence-state="active")
    assert html =~ ~s(aria-hidden="true")
    refute html =~ "aria-label="
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

  test "renderer maps canonical workflow_progress_status_card through the native component boundary" do
    element =
      Components.workflow_progress_status_card(
        id: "rpc-test",
        name: "metagraph",
        progress_pct: 0.65,
        active_count: 3,
        blocked_count: 1,
        path: "lib/metagraph"
      )

    html = render_component(&LiveUi.Renderer.render/1, %{element: element})

    assert html =~ ~s(data-live-ui-widget="workflow-progress-status-card")
    assert html =~ ~s(data-subject-card="metagraph")
    assert html =~ ~s(role="progressbar")
    assert html =~ ~s(aria-valuenow="65")
    assert html =~ ~s(3 active)
    assert html =~ ~s(1 blocked)
  end

  test "renderer preserves workflow_progress_status_card selected state in native output" do
    element =
      Components.workflow_progress_status_card(
        id: "rpc-selected",
        name: "ash_ui",
        progress_pct: 0.5,
        active_count: 2,
        blocked_count: 0,
        selected?: true
      )

    html = render_component(&LiveUi.Renderer.render/1, %{element: element})

    assert html =~ ~s(data-selected="true")
    assert html =~ ~s(live-ui-workflow-progress-status-card--selected)
  end

  test "renderer maps canonical diff_banner through native feedback boundary" do
    element =
      Feedback.diff_banner(
        id: "ask-diff",
        new_count: 3,
        changed_count: 5,
        removed_count: 1,
        active_filter: :new,
        filter_intent: :filter_diff
      )

    html =
      render_component(&LiveUi.Renderer.render/1, %{
        element: element,
        event_target: %Phoenix.LiveComponent.CID{cid: 1}
      })

    assert html =~ ~s(data-live-ui-widget-boundary="diff_banner")
    assert html =~ ~s(data-live-ui-widget="diff-banner")
    assert html =~ ~s(data-active-filter="new")
    assert html =~ "9 all"
    assert html =~ "3 new"
    assert html =~ ~s(phx-click="canonical_interaction")
    assert html =~ ~s(phx-value-widget="diff_banner")
    assert html =~ ~s(phx-value-selected_value="new")
    refute html =~ "live_ui_interaction"
  end
end
