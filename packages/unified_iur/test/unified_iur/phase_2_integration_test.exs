defmodule UnifiedIUR.Phase2IntegrationTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Binding
  alias UnifiedIUR.Container
  alias UnifiedIUR.Core.Invariant
  alias UnifiedIUR.Element
  alias UnifiedIUR.Forms
  alias UnifiedIUR.Layout
  alias UnifiedIUR.Reference
  alias UnifiedIUR.Tree
  alias UnifiedIUR.Widgets.{Data, Feedback, Foundational, Input, Navigation}

  test "phase 2 foundational widgets compose correctly inside box, row, column, and stack layouts" do
    title =
      Foundational.text("Unified IUR",
        id: "hero-title",
        style_refs: [:headline],
        accessibility: [label: "Hero title"]
      )

    subtitle = Foundational.text("Portable canonical UI", id: "hero-subtitle")
    save = Foundational.button("Save", id: "save-button", emphasis: :strong)
    cancel = Foundational.link("Cancel", "/cancel", id: "cancel-link")

    actions =
      Layout.row(
        [
          {:primary, save},
          {:secondary, cancel}
        ],
        id: "hero-actions",
        gap: 2,
        justify: :start
      )

    hero =
      Container.box(
        [
          {:content, title},
          {:content, subtitle},
          {:content, actions}
        ],
        id: "hero-box",
        padding: 2,
        gap: 1
      )

    shell =
      Layout.column(
        [
          {:header, hero},
          {:body, Layout.stack([{:base, hero}], id: "hero-stack")}
        ],
        id: "shell-column",
        gap: 2
      )

    assert [
             "shell-column",
             "hero-box",
             "hero-title",
             "hero-subtitle",
             "hero-actions",
             "save-button",
             "cancel-link",
             "hero-stack",
             "hero-box",
             "hero-title",
             "hero-subtitle",
             "hero-actions",
             "save-button",
             "cancel-link"
           ] ==
             Enum.map(Tree.depth_first(shell), & &1.id)

    assert %{
             total_elements: 14,
             type_histogram: %{layout: 6, widget: 8}
           } = Reference.summarize_tree(shell)
  end

  test "phase 2 input widgets and form containers preserve bound-value and label relationships" do
    email_input =
      Input.text_input(
        id: "email-input",
        name: :email,
        path: [:profile, :email],
        value: "user@example.com",
        required?: true
      )

    role_input =
      Input.select(
        [
          [value: :admin, label: "Admin"],
          [value: :viewer, label: "Viewer", selected?: true]
        ],
        id: "role-select",
        name: :role,
        value: :viewer
      )

    email_field = Forms.field(email_input, id: "email-field", label: "Email", help: "Required")
    role_field = Forms.field(role_input, id: "role-field", label: "Role")

    form =
      Forms.form_builder(
        [
          {:fields,
           Forms.field_group(
             [
               {:fields, email_field},
               {:fields, role_field}
             ],
             id: "identity-group",
             legend: "Identity"
           )},
          {:actions, Foundational.button("Save", id: "profile-save")}
        ],
        id: "profile-form",
        name: :profile,
        path: [:profile],
        submit_intent: :save_profile
      )

    assert %Element{kind: :form_builder} = form

    assert %Element{
             kind: :field,
             attributes: %{
               field: %{control_id: "email-input", label_slot: :label, help_slot: :help}
             }
           } =
             Tree.find_by_id(form, "email-field")

    assert %Element{
             kind: :label,
             attributes: %{label: %{for: "email-input", relationship: :field_label}}
           } = Tree.find_by_id(form, "email-input-label")

    assert %Element{
             kind: :text_input,
             attributes: %{
               bindings: [
                 %Binding{name: :email, path: [:profile, :email], value: "user@example.com"}
               ]
             }
           } = Tree.find_by_id(form, "email-input")
  end

  test "phase 2 split and scroll-oriented containers preserve stable canonical child shape and metadata" do
    nav =
      Data.list(
        [
          [id: :overview, label: "Overview", selected?: true],
          [id: :details, label: "Details"]
        ],
        id: "nav-list"
      )

    detail =
      Container.box(
        [
          {:content, Foundational.label("Detail", id: "detail-label")},
          {:content, Foundational.text("Large body", id: "detail-copy")}
        ],
        id: "detail-box",
        padding: 1
      )

    viewport = Layout.scroll_region(detail, id: "detail-viewport", offset: 12, height: 40)

    scroll_bar =
      Layout.scroll_bar(
        id: "detail-scrollbar",
        position: 12,
        viewport_size: 40,
        content_size: 120
      )

    split =
      Layout.split_pane(
        nav,
        Layout.row(
          [
            {:content, viewport},
            {:scrollbar, scroll_bar}
          ],
          id: "detail-row",
          gap: 1
        ),
        id: "workspace-split",
        ratio: 0.25
      )

    updated =
      Tree.update(split, "detail-viewport", fn element ->
        Element.put_attribute(element, :viewport, %{
          axis: :vertical,
          offset: 24,
          clip?: true,
          scrollbars: :auto,
          height: 40
        })
      end)

    assert :ok = Invariant.assert_shape_stable!(split, updated)

    assert %Element{kind: :viewport, children: [%{slot: :content}]} =
             Tree.find_by_id(split, "detail-viewport")

    assert %Element{kind: :scroll_bar} = Tree.find_by_id(split, "detail-scrollbar")
  end

  test "phase 2 navigation and data-view constructs share stable item and state semantics" do
    menu =
      Navigation.menu(
        [
          [id: :home, label: "Home", active?: true],
          [id: :settings, label: "Settings"]
        ],
        id: "main-menu",
        active_item: :home
      )

    tabs =
      Navigation.tabs(
        [
          [id: :overview, label: "Overview", active?: true],
          [id: :activity, label: "Activity"]
        ],
        id: "main-tabs",
        active_item: :overview
      )

    table =
      Data.table(
        [
          [id: :name, label: "Name"],
          [id: :status, label: "Status"]
        ],
        [
          [id: "row-1", cells: ["Spec", "Ready"], selected?: true]
        ],
        id: "artifact-table"
      )

    tree =
      Data.tree_view(
        [
          [id: :root, label: "Root", expanded?: true, children: [[id: :child, label: "Child"]]]
        ],
        id: "artifact-tree"
      )

    screen =
      Layout.column(
        [
          {:navigation, menu},
          {:navigation, tabs},
          {:content, table},
          {:content, tree}
        ],
        id: "data-screen"
      )

    assert %{
             total_elements: 5,
             type_histogram: %{layout: 1, widget: 4}
           } = Reference.summarize_tree(screen)

    assert %{navigation: %{active_item: :home}} = Tree.find_by_id(screen, "main-menu").attributes

    assert %{tree: %{nodes: [%{expanded?: true}]}} =
             Tree.find_by_id(screen, "artifact-tree").attributes
  end

  test "phase 2 feedback and progress constructs compose with foundational styling hooks" do
    status = Feedback.status("Idle", id: "service-status", severity: :info, status: :idle)

    progress =
      Feedback.progress(
        id: "sync-progress",
        current: 3,
        total: 10,
        label: "Sync",
        status: :running
      )

    gauge = Feedback.gauge(id: "cpu-gauge", value: 72, label: "CPU", severity: :warning)

    feedback =
      Feedback.inline_feedback("Configuration saved.",
        id: "save-feedback",
        title: "Saved",
        severity: :success
      )

    shell =
      Container.box(
        [
          {:content,
           Foundational.label("System", id: "system-label", style_refs: [:section_label])},
          {:content, status},
          {:content, progress},
          {:content, gauge},
          {:content, feedback}
        ],
        id: "feedback-box",
        padding: 1
      )

    assert %Element{kind: :box} = shell

    assert %{
             theme: %{
               component: :label,
               token_refs: [%{kind: :token_ref, path: [:section_label]}]
             }
           } =
             Tree.find_by_id(shell, "system-label").attributes

    assert %{feedback: %{severity: :success}} = Tree.find_by_id(shell, "save-feedback").attributes
    assert %{feedback: %{status: :running}} = Tree.find_by_id(shell, "sync-progress").attributes
  end

  test "phase 2 equivalent authored inputs yield deterministic canonical shapes for foundational constructs" do
    left =
      Forms.form_builder(
        [
          {:fields,
           Forms.field(
             Input.text_input(
               id: "username-input",
               name: :username,
               value: "pascal",
               placeholder: "Username"
             ),
             id: "username-field",
             label: "Username"
           )}
        ],
        id: "username-form",
        name: :account,
        path: [:account]
      )

    right =
      Forms.form_builder(
        [
          {:fields,
           Forms.field(
             Input.text_input(%{
               "id" => "username-input",
               "name" => :username,
               "value" => "pascal",
               "placeholder" => "Username"
             }),
             %{
               "id" => "username-field",
               "label" => "Username"
             }
           )}
        ],
        %{
          "id" => "username-form",
          "name" => :account,
          "path" => [:account]
        }
      )

    assert :ok = Invariant.assert_shape_stable!(left, right)
    assert Tree.shape_signature(left) == Tree.shape_signature(right)

    assert Reference.summarize_tree(left).type_histogram ==
             Reference.summarize_tree(right).type_histogram
  end
end
