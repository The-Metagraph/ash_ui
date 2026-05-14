defmodule ElmUi.NativeWidgetsTest do
  use ExUnit.Case, async: true

  test "foundational constructors build direct-use widget contracts" do
    text = ElmUi.Widgets.text("workspace-title", "Workspace")
    button = ElmUi.Widgets.button("save-button", "Save", on_click: %{intent: :save_workspace})

    content =
      ElmUi.Widgets.content("workspace-header", [text, button],
        presentation: :hero,
        tone: :accent,
        variant: :hero,
        background: :panel,
        border: :subtle,
        style_hooks: [:tone, :variant, :theme_tokens],
        theme_tokens: %{surface: [:surface, :default]},
        state_variants: %{focused: %{border: :focus_ring}}
      )

    assert text.kind == :text
    assert text.family == :content
    assert button.events == %{click: %{intent: :save_workspace}}
    assert content.attributes.presentation == :hero
    assert content.slot_children.default == [text, button]
    assert content.styles.hooks == [:tone, :variant, :theme_tokens]
    assert content.styles.tone == :accent
    assert content.styles.variant == :hero
    assert content.styles.background == :panel
    assert content.styles.theme_tokens.surface == [:surface, :default]
    assert content.styles.state_variants.focused.border == :focus_ring
  end

  test "input, navigation, layout, and grouped form widgets compose deterministically" do
    input =
      ElmUi.Widgets.text_input("name-input",
        name: :name,
        value: "Pascal",
        placeholder: "Name",
        on_change: %{intent: :rename_profile}
      )

    field =
      ElmUi.Widgets.field("name-field", input,
        name: :name,
        label: "Display Name",
        help: "Shown in navigation"
      )

    group = ElmUi.Widgets.field_group("identity-group", [field], legend: "Identity")
    form = ElmUi.Widgets.form("profile-form", [group], on_submit: %{intent: :save_profile})

    tabs =
      ElmUi.Widgets.tabs(
        "profile-tabs",
        [
          [id: :overview, label: "Overview", active: true],
          [id: :activity, label: "Activity"]
        ],
        active_item: :overview,
        on_navigate: %{intent: :switch_tab}
      )

    layout = ElmUi.Widgets.column("profile-layout", [form, tabs], gap: :lg)

    assert input.events == %{change: %{intent: :rename_profile}}
    assert hd(field.slot_children.label).kind == :label
    assert hd(field.slot_children.help).kind == :text
    assert field.slot_children.control == [input]
    assert form.events == %{submit: %{intent: :save_profile}}
    assert tabs.attributes.active_item == :overview
    assert tabs.events == %{navigation: %{intent: :switch_tab}}
    assert layout.kind == :column
    assert Enum.map(layout.slot_children.default, & &1.id) == ["profile-form", "profile-tabs"]
  end

  test "widgets catalog exposes foundational families and constructor modules" do
    modules = ElmUi.Widgets.modules()

    assert ElmUi.Widgets.Foundational in modules
    assert ElmUi.Widgets.Input in modules
    assert ElmUi.Widgets.Navigation in modules
    assert ElmUi.Widgets.Layout in modules
    assert ElmUi.Widgets.Layered in modules
    assert ElmUi.Widgets.Forms in modules
    assert ElmUi.Widgets.Data in modules
    assert ElmUi.Widgets.Feedback in modules
    assert ElmUi.Widgets.Visualization in modules
    assert ElmUi.Widgets.Operational in modules

    assert :content in ElmUi.Widgets.kinds()
    assert :numeric_input in ElmUi.Widgets.kinds()
    assert :grid in ElmUi.Widgets.kinds()
    assert :list in ElmUi.Widgets.kinds()
    assert :form_builder in ElmUi.Widgets.kinds()
    assert :form in ElmUi.Widgets.kinds()
    assert :viewport in ElmUi.Widgets.kinds()
    assert :dialog in ElmUi.Widgets.kinds()
    assert :markdown_viewer in ElmUi.Widgets.kinds()
    assert :bar_chart in ElmUi.Widgets.kinds()
    assert :navigation in ElmUi.Widgets.families()
    assert :document in ElmUi.Widgets.families()
    assert :layer in ElmUi.Widgets.families()
    assert :operational in ElmUi.Widgets.families()
    assert ElmUi.Widgets.validation_state().form_composition == :ready
    assert ElmUi.Widgets.validation_state().advanced_data_widgets == :ready
    assert ElmUi.Widgets.validation_state().display_system_widgets == :ready
  end

  test "semantic foundational, data, and form widgets are available natively" do
    badge =
      ElmUi.Widgets.badge("runtime-badge", "Live",
        icon: :sparkles,
        icon_set: :system,
        presentation: :pill
      )

    hero =
      ElmUi.Widgets.hero(
        "docs-hero",
        [ElmUi.Widgets.text("hero-copy", "Semantic widgets stay semantic.")],
        eyebrow: "ElmUi",
        title: "Ship richer dashboards",
        message: "Preserve authored meaning through the web runtime.",
        actions: [ElmUi.Widgets.button("hero-action", "Explore")]
      )

    stat =
      ElmUi.Widgets.stat("artifact-stat",
        title: "Artifacts shipped",
        value: "24",
        message: "Across the current release train"
      )

    key_value =
      ElmUi.Widgets.key_value("owner-pair", "Owner", "Docs team",
        description: "Maintaining semantic widget coverage"
      )

    info_list =
      ElmUi.Widgets.info_list(
        "semantic-list",
        [
          [
            id: :semantic,
            title: "Semantic widgets",
            value: "In progress",
            description: "Adding badge, hero, stat, key_value, and info_list",
            icon: :sparkles,
            status: :active
          ]
        ],
        ordered: true,
        empty_state: "No semantic notes"
      )

    form_field =
      ElmUi.Widgets.form_field(
        "dashboard-name",
        ElmUi.Widgets.text_input("dashboard-name-input", name: :dashboard_name),
        name: :dashboard_name,
        label: "Dashboard name",
        help: "Used in admin and docs views"
      )

    assert badge.kind == :badge
    assert badge.attributes.presentation == :pill
    assert hero.kind == :hero
    assert hero.attributes.eyebrow == "ElmUi"
    assert hero.slot_children.actions |> hd() |> Map.fetch!(:kind) == :button
    assert stat.family == :data
    assert stat.attributes.value == "24"
    assert key_value.kind == :key_value
    assert info_list.kind == :info_list
    assert info_list.attributes.ordered
    assert form_field.kind == :form_field
    assert hd(form_field.slot_children.label).kind == :label
    assert hd(form_field.slot_children.help).kind == :text
  end

  test "expanded native constructors cover the remaining canonical input, layout, and data kinds" do
    numeric_input =
      ElmUi.Widgets.numeric_input("count-input", name: :count, value: 7, min: 0, max: 10)

    date_input = ElmUi.Widgets.date_input("launch-date", name: :launch_date, value: "2026-03-21")
    time_input = ElmUi.Widgets.time_input("launch-time", name: :launch_time, value: "09:30")

    file_input =
      ElmUi.Widgets.file_input("upload-input", name: :artifact, accept: [".csv"], multiple: true)

    slider = ElmUi.Widgets.slider("threshold-slider", name: :threshold, value: 80, max: 100)
    toggle = ElmUi.Widgets.toggle("alerts-toggle", name: :alerts, checked: true)

    radio_group =
      ElmUi.Widgets.radio_group(
        "mode-input",
        [
          [id: :auto, label: "Auto", value: :auto],
          [id: :manual, label: "Manual", value: :manual]
        ],
        name: :mode,
        value: :auto
      )

    pick_list =
      ElmUi.Widgets.pick_list(
        "targets-input",
        [
          [id: "node-a", label: "Node A", value: "node-a"],
          [id: "node-b", label: "Node B", value: "node-b"]
        ],
        name: :targets,
        value: ["node-a"]
      )

    form_builder =
      ElmUi.Widgets.form_builder("controls-form", [
        ElmUi.Widgets.field("threshold-field", slider, name: :threshold, label: "Threshold")
      ])

    grid =
      ElmUi.Widgets.grid(
        "ops-grid",
        [
          ElmUi.Widgets.text("grid-copy", "Grid item"),
          ElmUi.Widgets.button("grid-action", "Run")
        ],
        columns: 2,
        gap: :md
      )

    list =
      ElmUi.Widgets.list(
        "node-list",
        [[id: "node-a", label: "Node A", value: "node-a", selected: true]],
        ordered: true,
        selection_mode: :single
      )

    assert numeric_input.kind == :numeric_input
    assert date_input.kind == :date_input
    assert time_input.kind == :time_input
    assert file_input.kind == :file_input
    assert slider.kind == :slider
    assert toggle.kind == :toggle
    assert radio_group.kind == :radio_group
    assert pick_list.kind == :pick_list
    assert form_builder.kind == :form_builder
    assert grid.kind == :grid
    assert list.kind == :list
    assert list.family == :data
    assert ElmUi.Renderer.required_canonical_kinds() -- ElmUi.Widgets.kinds() == []
  end

  test "advanced widget families normalize deterministic data, feedback, visualization, and operational state" do
    table =
      ElmUi.Widgets.table(
        "cluster-table",
        [
          [id: :name, label: "Name", sortable: true],
          [id: :status, label: "Status"]
        ],
        [
          [id: "node-a", cells: ["Node A", "healthy"], selected: true],
          [id: "node-b", cells: ["Node B", "degraded"]]
        ],
        sort_key: :name,
        sort_direction: :asc,
        filters: [[field: :status, operator: :eq, value: :healthy]],
        page: 1,
        page_size: 20,
        total_entries: 42,
        on_sort: %{intent: :sort_cluster}
      )

    markdown =
      ElmUi.Widgets.markdown_viewer(
        "ops-doc",
        "# Operations\n\nHealthy systems.",
        anchors: [[id: "operations", label: "Operations", level: 1]]
      )

    progress = ElmUi.Widgets.progress("deploy-progress", current: 3, total: 5, label: "Deploy")
    sparkline = ElmUi.Widgets.sparkline("cpu-sparkline", [4, 5, 7, 6])

    palette =
      ElmUi.Widgets.command_palette(
        "ops-command-palette",
        [
          [id: :restart_node, label: "Restart Node"],
          [id: :drain_node, label: "Drain Node"]
        ],
        query: "rest",
        placeholder: "Run command",
        on_command: %{intent: :run_command}
      )

    assert table.family == :data
    assert table.events == %{sort: %{intent: :sort_cluster}}
    assert table.attributes.sorting == %{key: :name, direction: :asc}
    assert table.attributes.pagination.total_entries == 42
    assert markdown.family == :document
    assert hd(markdown.attributes.anchors).id == "operations"
    assert progress.family == :feedback
    assert progress.attributes.total == 5
    assert sparkline.family == :visualization
    assert hd(sparkline.attributes.series).values == [4, 5, 7, 6]
    assert palette.family == :operational
    assert palette.events == %{command: %{intent: :run_command}}
    assert palette.attributes.query == "rest"
  end

  test "layout and layer entrypoints expose advanced display and overlay primitives" do
    viewport =
      ElmUi.Layout.viewport(
        "log-viewport",
        ElmUi.Widgets.log_viewer(
          "ops-log-viewer",
          [[id: "log-1", message: "Connected", severity: :info]]
        ),
        offset: {0, 240},
        height: 24,
        scrollbars: :auto,
        sync_group: :logs,
        on_scroll: %{intent: :scroll_logs}
      )

    split =
      ElmUi.Layout.split_pane(
        "operations-split",
        viewport,
        ElmUi.Widgets.content("details-panel", [
          ElmUi.Widgets.text("details-text", "Details")
        ]),
        ratio: 0.6,
        on_resize: %{intent: :resize_split}
      )

    dialog =
      ElmUi.Layer.dialog(
        "inspect-dialog",
        ElmUi.Widgets.content("dialog-content", [
          ElmUi.Widgets.text("dialog-copy", "Inspect node")
        ]),
        title: "Inspect Node",
        modal: true
      )

    toast =
      ElmUi.Layer.toast(
        "ops-toast",
        ElmUi.Widgets.text("toast-copy", "Node restarted"),
        placement: :top_end
      )

    overlay =
      ElmUi.Layer.overlay("operations-overlay", split, [dialog, toast],
        on_dismiss: %{intent: :dismiss}
      )

    scroll_bar = ElmUi.Layout.scroll_bar("log-scrollbar", viewport_ref: "log-viewport")

    assert ElmUi.layout() == ElmUi.Layout
    assert ElmUi.layer() == ElmUi.Layer
    assert viewport.kind == :viewport
    assert viewport.attributes.offset == %{x: 0, y: 240}
    assert viewport.events == %{scroll: %{intent: :scroll_logs}}
    assert split.slot_children.primary == [viewport]
    assert split.events == %{resize: %{intent: :resize_split}}
    assert dialog.kind == :dialog
    assert dialog.attributes.modal
    assert overlay.kind == :overlay
    assert Enum.map(overlay.slot_children.layers, & &1.kind) == [:dialog, :toast]
    assert overlay.events == %{dismiss: %{intent: :dismiss}}
    assert scroll_bar.kind == :scroll_bar
  end

  test "display-system and layer widgets reject invalid configuration with actionable diagnostics" do
    viewport =
      ElmUi.Layout.viewport(
        "primary-viewport",
        ElmUi.Widgets.content("primary-content", [ElmUi.Widgets.text("copy", "Primary")])
      )

    content =
      ElmUi.Widgets.content("secondary-content", [
        ElmUi.Widgets.text("secondary-copy", "Secondary")
      ])

    assert_raise ArgumentError, ~r/split_pane widgets require a :ratio between 0 and 1/, fn ->
      ElmUi.Layout.split_pane("invalid-split", viewport, content, ratio: 1.2)
    end

    assert_raise ArgumentError,
                 ~r/scroll_bar widgets require either :viewport_ref or :sync_group/,
                 fn ->
                   ElmUi.Layout.scroll_bar("invalid-scroll")
                 end

    assert_raise ArgumentError,
                 ~r/overlay widgets require every overlay layer to use the :layer family/,
                 fn ->
                   ElmUi.Layer.overlay("invalid-overlay", content, [content])
                 end
  end

  test "example coverage validates canonical surface parity directly against unified_iur kinds" do
    report = ElmUi.Validate.example_coverage()

    assert report.status == :pass
    assert Enum.empty?(report.findings)
  end
end
