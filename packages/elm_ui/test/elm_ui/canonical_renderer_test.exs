defmodule ElmUi.CanonicalRendererTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.{Forms, Interaction, Layout, Token, Viewport}
  alias UnifiedIUR.Element
  alias UnifiedIUR.Element.Child
  alias UnifiedIUR.Widgets.{Data, Foundational, Input}

  test "canonical foundational structures map into the native elm_ui widget model" do
    canonical =
      Element.new(:layout, :column,
        id: "workspace-layout",
        children: [
          Element.new(:widget, :text, id: "workspace-title", attributes: %{content: "Workspace"}),
          Element.new(:composite, :form,
            id: "workspace-form",
            children: [
              Element.new(:composite, :field_group,
                id: "query-group",
                attributes: %{legend: "Search"},
                children: [
                  Element.new(:composite, :field,
                    id: "query-field",
                    attributes: %{name: :query},
                    children: [
                      Child.new(
                        :control,
                        Element.new(:widget, :text_input,
                          id: "query-input",
                          attributes: %{name: :query, value: "Pascal", placeholder: "Search"}
                        )
                      )
                    ]
                  )
                ]
              )
            ]
          )
        ]
      )

    assert {:ok, %ElmUi.Widget{kind: :column} = root} = ElmUi.Renderer.render(canonical)
    assert Enum.map(root.slot_children.default, & &1.id) == ["workspace-title", "workspace-form"]

    input_widget = find_widget(root, "query-input")

    assert input_widget.kind == :text_input
    assert input_widget.attributes.name == :query
    assert input_widget.attributes.value == "Pascal"
  end

  test "canonical view state reuses the same split runtime path as native screens" do
    canonical =
      Element.new(:layout, :column,
        id: "workspace-layout",
        children: [
          Element.new(:widget, :text, id: "workspace-title", attributes: %{content: "Workspace"}),
          Element.new(:widget, :checkbox,
            id: "alerts-checkbox",
            attributes: %{name: :alerts, checked: true, label: "Alerts"}
          )
        ]
      )

    assert {:ok, runtime_state} =
             ElmUi.Runtime.mount_iur_screen(canonical,
               runtime_id: "canonical-workspace",
               title: "Canonical Workspace"
             )

    assert {:ok, model} = ElmUi.Runtime.hydrate_frontend(runtime_state)
    assert runtime_state.boundary_mode == :canonical_boundary
    assert find_node(model.tree, "alerts-checkbox").tag == "input"
  end

  test "advanced canonical widgets and layered display nodes map into the native elm_ui model" do
    canonical =
      Element.new(:layer, :overlay,
        id: "ops-overlay",
        children: [
          Child.new(
            :base,
            Element.new(:layout, :split_pane,
              id: "ops-split",
              attributes: %{ratio: 0.6},
              children: [
                Child.new(
                  :primary,
                  Element.new(:layout, :viewport,
                    id: "log-viewport",
                    attributes: %{offset: %{x: 0, y: 120}, scrollbars: :auto},
                    children: [
                      Child.new(
                        :content,
                        Element.new(:widget, :table,
                          id: "cluster-table",
                          attributes: %{
                            columns: [%{id: :name, label: "Name"}],
                            rows: [%{id: "node-a", cells: ["Node A"]}]
                          }
                        )
                      )
                    ]
                  )
                ),
                Child.new(
                  :secondary,
                  Element.new(:widget, :status,
                    id: "status-banner",
                    attributes: %{text: "Watching cluster", severity: :info}
                  )
                )
              ]
            )
          ),
          Child.new(
            :layers,
            Element.new(:layer, :dialog,
              id: "inspect-dialog",
              attributes: %{title: "Inspect Node", modal: false},
              children: [
                Child.new(
                  :content,
                  Element.new(:widget, :markdown_viewer,
                    id: "dialog-doc",
                    attributes: %{source: "# Inspect"}
                  )
                )
              ]
            )
          )
        ]
      )

    assert {:ok, %ElmUi.Widget{kind: :overlay} = root} = ElmUi.Renderer.render(canonical)
    assert Enum.map(root.slot_children.layers, & &1.id) == ["inspect-dialog"]

    viewport = find_widget(root, "log-viewport")
    dialog = find_widget(root, "inspect-dialog")
    table = find_widget(root, "cluster-table")

    assert viewport.kind == :viewport
    assert viewport.attributes.offset == %{x: 0, y: 120}
    assert dialog.kind == :dialog
    refute dialog.attributes.modal
    assert table.family == :data
  end

  test "advanced canonical screens reuse the same runtime hydration path as native advanced screens" do
    canonical =
      Element.new(:layer, :overlay,
        id: "ops-overlay",
        children: [
          Child.new(
            :base,
            Element.new(:layout, :viewport,
              id: "log-viewport",
              attributes: %{offset: 64},
              children: [
                Child.new(
                  :content,
                  Element.new(:widget, :log_viewer,
                    id: "ops-log-viewer",
                    attributes: %{entries: [%{id: "entry-1", message: "Connected"}]}
                  )
                )
              ]
            )
          ),
          Child.new(
            :layers,
            Element.new(:layer, :dialog,
              id: "inspect-dialog",
              attributes: %{title: "Inspect Node"},
              children: [
                Child.new(
                  :content,
                  Element.new(:widget, :inline_feedback,
                    id: "dialog-feedback",
                    attributes: %{message: "Inspecting", severity: :info}
                  )
                )
              ]
            )
          )
        ]
      )

    assert {:ok, runtime_state} =
             ElmUi.Runtime.mount_iur_screen(canonical,
               runtime_id: "canonical-advanced",
               title: "Canonical Advanced"
             )

    assert {:ok, model} = ElmUi.Runtime.hydrate_frontend(runtime_state)

    assert find_node(model.tree, "log-viewport").role == "region"
    assert find_node(model.tree, "inspect-dialog").tag == "dialog"
    assert find_node(model.tree, "inspect-dialog").browser.focusable?
  end

  test "semantic canonical widgets map into the native elm_ui model" do
    canonical =
      Element.new(:layout, :column,
        id: "semantic-dashboard",
        children: [
          Foundational.hero(
            [
              {:supporting,
               Foundational.text("Semantic widgets stay semantic.", id: "hero-copy")},
              {:actions, Foundational.button("Explore", id: "hero-action")}
            ],
            id: "docs-hero",
            eyebrow: "ElmUi",
            title: "Ship richer dashboards",
            message: "Author semantic structure once and lower it into IUR."
          ),
          Data.stat(
            id: "artifact-stat",
            title: "Artifacts shipped",
            value: "24",
            message: "Across the current release train"
          ),
          Data.key_value("Owner", "Docs team",
            id: "owner-pair",
            description: "Maintaining semantic widget coverage"
          ),
          Data.info_list(
            [
              [
                id: :semantic,
                title: "Semantic widgets",
                value: "In progress",
                description: "Adding badge, hero, stat, key_value, and info_list"
              ]
            ],
            id: "semantic-list",
            ordered?: true,
            empty_state: "No semantic notes"
          ),
          Forms.form_builder(
            [
              Forms.form_field(
                Input.text_input(id: "dashboard-name-input", binding: %{name: :dashboard_name}),
                id: "dashboard-name",
                name: :dashboard_name,
                label: "Dashboard name",
                help: "Used in admin and docs views"
              )
            ],
            id: "settings-form"
          )
        ]
      )

    assert {:ok, %ElmUi.Widget{kind: :column} = root} = ElmUi.Renderer.render(canonical)

    hero = find_widget(root, "docs-hero")
    stat = find_widget(root, "artifact-stat")
    key_value = find_widget(root, "owner-pair")
    info_list = find_widget(root, "semantic-list")
    form_field = find_widget(root, "dashboard-name")

    assert hero.kind == :hero
    assert hero.attributes.eyebrow == "ElmUi"
    assert Enum.map(hero.slot_children.supporting, & &1.id) == ["hero-copy"]
    assert Enum.map(hero.slot_children.actions, & &1.id) == ["hero-action"]
    assert stat.kind == :stat
    assert key_value.kind == :key_value
    assert info_list.kind == :info_list
    assert info_list.attributes.ordered
    assert form_field.kind == :form_field
    assert hd(form_field.slot_children.control).id == "dashboard-name-input"
  end

  test "canonical panel layouts map into the native layout surface" do
    canonical =
      Element.new(:layout, :panel,
        id: "settings-panel",
        attributes: %{title: "Settings", tone: :muted},
        children: [
          Element.new(:widget, :text,
            id: "settings-copy",
            attributes: %{content: "Panel body"}
          )
        ]
      )

    assert {:ok, %ElmUi.Widget{kind: :panel} = root} = ElmUi.Renderer.render(canonical)
    assert root.attributes.title == "Settings"
    assert root.attributes.tone == :muted
    assert Enum.map(root.slot_children.default, & &1.id) == ["settings-copy"]
  end

  test "renderer consumes constructor-built canonical inputs, grid layouts, and theme attachments" do
    canonical = constructor_based_screen()

    assert {:ok, %ElmUi.Widget{kind: :column} = root} = ElmUi.Renderer.render(canonical)

    ops_grid = find_widget(root, "ops-grid")
    launch_button = find_widget(root, "launch-button")
    controls_form = find_widget(root, "controls-form")
    numeric_input = find_widget(root, "numeric-input")
    toggle = find_widget(root, "alerts-toggle")
    radio_group = find_widget(root, "mode-input")
    pick_list = find_widget(root, "targets-input")
    slider = find_widget(root, "threshold-input")
    date_input = find_widget(root, "launch-date")
    time_input = find_widget(root, "launch-time")
    file_input = find_widget(root, "upload-input")
    node_list = find_widget(root, "node-list")

    assert ops_grid.kind == :grid
    assert launch_button.events.click.intent == :launch_flow
    assert launch_button.styles.variant == :primary
    assert launch_button.styles.tone == :accent
    assert launch_button.styles.theme_tokens["button_primary"] == [:button, :primary]
    assert controls_form.kind == :form_builder
    assert numeric_input.kind == :numeric_input
    assert numeric_input.attributes.name == :count
    assert numeric_input.attributes.value == 42
    assert toggle.kind == :toggle
    assert toggle.state.checked
    assert radio_group.kind == :radio_group
    assert pick_list.kind == :pick_list
    assert slider.kind == :slider
    assert date_input.kind == :date_input
    assert time_input.kind == :time_input
    assert file_input.kind == :file_input
    assert file_input.attributes.multiple
    assert node_list.kind == :list
    assert node_list.attributes.ordered
  end

  test "constructor-built canonical widgets preserve meaning through runtime hydration" do
    assert {:ok, runtime_state} =
             ElmUi.Runtime.mount_iur_screen(
               constructor_based_screen(),
               runtime_id: "constructor-canonical",
               title: "Constructor Canonical"
             )

    assert {:ok, model} = ElmUi.Runtime.hydrate_frontend(runtime_state)

    assert runtime_state.boundary_mode == :canonical_boundary
    assert find_node(model.tree, "ops-grid").role == "grid"
    assert find_node(model.tree, "numeric-input").role == "spinbutton"
    assert find_node(model.tree, "alerts-toggle").role == "switch"
    assert find_node(model.tree, "mode-input").role == "radiogroup"
    assert find_node(model.tree, "node-list").role == "list"

    launch_button = find_node(model.tree, "launch-button")

    assert launch_button.styles.authored.variant == :primary
    assert launch_button.styles.authored.tone == :accent
    assert launch_button.diagnostics.event_names == [:click]
  end

  defp find_widget(%ElmUi.Widget{id: id} = widget, id), do: widget

  defp find_widget(%ElmUi.Widget{} = widget, id) do
    widget.slot_children
    |> Map.values()
    |> List.flatten()
    |> Enum.find_value(&find_widget(&1, id))
  end

  defp find_widget(nil, _id), do: nil

  defp constructor_based_screen do
    Layout.column(
      [
        Layout.grid(
          [
            Foundational.text("Operations Workspace", id: "ops-title"),
            Foundational.button("Launch",
              id: "launch-button",
              interaction: Interaction.click(intent: :launch_flow),
              style: %{emphasis: %{tone: :accent}},
              theme: %{variant: :primary, token_refs: [Token.ref([:button, :primary])]}
            )
          ],
          id: "ops-grid",
          columns: 2,
          gap: :md
        ),
        Forms.form_builder(
          [
            Forms.field_group(
              [
                Forms.field(
                  Input.numeric_input(
                    id: "numeric-input",
                    binding: %{name: :count, value: 42},
                    min: 1,
                    max: 99,
                    step: 3
                  ),
                  id: "numeric-field",
                  name: :count,
                  label: "Count"
                ),
                Forms.field(
                  Input.toggle(
                    id: "alerts-toggle",
                    binding: %{name: :alerts, value: true}
                  ),
                  id: "alerts-field",
                  name: :alerts,
                  label: "Alerts"
                ),
                Forms.field(
                  Input.radio_group(
                    [
                      %{id: :auto, label: "Auto", value: :auto, selected?: true},
                      %{id: :manual, label: "Manual", value: :manual}
                    ],
                    id: "mode-input",
                    binding: %{name: :mode, value: :auto}
                  ),
                  id: "mode-field",
                  name: :mode,
                  label: "Mode"
                ),
                Forms.field(
                  Input.pick_list(
                    [
                      %{id: "node-a", label: "Node A", value: "node-a", selected?: true},
                      %{id: "node-b", label: "Node B", value: "node-b"}
                    ],
                    id: "targets-input",
                    binding: %{name: :targets, value: ["node-a"]}
                  ),
                  id: "targets-field",
                  name: :targets,
                  label: "Targets"
                ),
                Forms.field(
                  Input.slider(
                    id: "threshold-input",
                    binding: %{name: :threshold, value: 70},
                    min: 0,
                    max: 100,
                    step: 5
                  ),
                  id: "threshold-field",
                  name: :threshold,
                  label: "Threshold"
                ),
                Forms.field(
                  Input.date_input(
                    id: "launch-date",
                    binding: %{name: :launch_date, value: "2026-03-21"}
                  ),
                  id: "date-field",
                  name: :launch_date,
                  label: "Launch Date"
                ),
                Forms.field(
                  Input.time_input(
                    id: "launch-time",
                    binding: %{name: :launch_time, value: "09:30"}
                  ),
                  id: "time-field",
                  name: :launch_time,
                  label: "Launch Time"
                ),
                Forms.field(
                  Input.file_input(
                    id: "upload-input",
                    binding: %{name: :artifact},
                    accept: [".csv"],
                    multiple?: true
                  ),
                  id: "upload-field",
                  name: :artifact,
                  label: "Artifact"
                )
              ],
              id: "controls-group",
              legend: "Controls"
            )
          ],
          id: "controls-form",
          interaction: Interaction.submit(intent: :save_controls)
        ),
        Data.list(
          [
            %{id: "node-a", label: "Node A", value: "node-a", selected?: true},
            %{id: "node-b", label: "Node B", value: "node-b"}
          ],
          id: "node-list",
          ordered?: true,
          selection_mode: :single
        ),
        Viewport.region(
          Foundational.content(
            [
              Foundational.text("Logs", id: "viewport-copy")
            ],
            id: "viewport-content"
          ),
          id: "ops-viewport",
          offset: {0, 120},
          scrollbars: :auto
        ),
        Viewport.scroll_bar(
          id: "ops-scrollbar",
          viewport_ref: "ops-viewport",
          position: {0.2, 0.4},
          viewport_size: 24,
          content_size: 120
        )
      ],
      id: "ops-root"
    )
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
