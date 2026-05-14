aligned_example_ids = [
  :alert_dialog,
  :bar_chart,
  :box,
  :button,
  :canvas,
  :checkbox,
  :cluster_dashboard,
  :column,
  :command_palette,
  :content,
  :context_menu,
  :date_input,
  :dialog,
  :field,
  :field_group,
  :file_input,
  :form_builder,
  :gauge,
  :grid,
  :icon,
  :image,
  :inline_feedback,
  :label,
  :line_chart,
  :link,
  :list,
  :log_viewer,
  :markdown_viewer,
  :menu,
  :numeric_input,
  :overlay,
  :pick_list,
  :process_monitor,
  :progress,
  :radio_group,
  :row,
  :scroll_bar,
  :select,
  :separator,
  :spacer,
  :sparkline,
  :split_pane,
  :status,
  :stream_widget,
  :supervision_tree_viewer,
  :table,
  :tabs,
  :text,
  :text_input,
  :time_input,
  :toast,
  :toggle,
  :tree_view,
  :viewport
]

defmodule LiveUi.Examples.Aligned do
  @moduledoc """
  Aligned `live_ui` maintainer examples that mirror the root `examples/` ids.
  """

  alias LiveUi.Examples.Aligned.Canonical

  @aligned_example_ids aligned_example_ids
  @family_map %{
    alert_dialog: :overlay,
    bar_chart: :feedback,
    box: :layout,
    button: :content,
    canvas: :display,
    checkbox: :input,
    cluster_dashboard: :operational,
    column: :layout,
    command_palette: :navigation,
    content: :content,
    context_menu: :overlay,
    date_input: :input,
    dialog: :overlay,
    field: :input,
    field_group: :input,
    file_input: :input,
    form_builder: :input,
    gauge: :feedback,
    grid: :layout,
    icon: :content,
    image: :content,
    inline_feedback: :feedback,
    label: :content,
    line_chart: :feedback,
    link: :content,
    list: :data,
    log_viewer: :data,
    markdown_viewer: :data,
    menu: :navigation,
    numeric_input: :input,
    overlay: :overlay,
    pick_list: :input,
    process_monitor: :operational,
    progress: :feedback,
    radio_group: :input,
    row: :layout,
    scroll_bar: :display,
    select: :input,
    separator: :layout,
    spacer: :layout,
    sparkline: :feedback,
    split_pane: :display,
    status: :feedback,
    stream_widget: :operational,
    supervision_tree_viewer: :operational,
    table: :data,
    tabs: :navigation,
    text: :content,
    text_input: :input,
    time_input: :input,
    toast: :overlay,
    toggle: :input,
    tree_view: :data,
    viewport: :display
  }
  @transport_review_ids MapSet.new([
                          :button,
                          :checkbox,
                          :command_palette,
                          :context_menu,
                          :date_input,
                          :file_input,
                          :link,
                          :list,
                          :menu,
                          :numeric_input,
                          :pick_list,
                          :radio_group,
                          :select,
                          :table,
                          :tabs,
                          :text_input,
                          :time_input,
                          :toggle,
                          :tree_view
                        ])
  @canonical_review_ids MapSet.new([
                          :button,
                          :checkbox,
                          :command_palette,
                          :context_menu,
                          :link,
                          :list,
                          :menu,
                          :pick_list,
                          :radio_group,
                          :select,
                          :table,
                          :tabs,
                          :text_input,
                          :toggle,
                          :tree_view
                        ])
  @screen_modules Enum.into(@aligned_example_ids, %{}, fn id ->
                    module =
                      id
                      |> Atom.to_string()
                      |> Macro.camelize()
                      |> then(&Module.concat(__MODULE__, &1))

                    {id, module}
                  end)

  @spec ids() :: [atom()]
  def ids do
    @aligned_example_ids
  end

  @spec modules() :: [module()]
  def modules do
    Enum.map(@aligned_example_ids, &screen_module/1)
  end

  @spec catalog() :: [map()]
  def catalog do
    Enum.map(@aligned_example_ids, &metadata/1)
  end

  @spec repository_example_ids() :: [atom()]
  def repository_example_ids do
    root_examples_dir = Path.expand("../../../../../examples", __DIR__)

    root_examples_dir
    |> File.ls!()
    |> Enum.filter(&File.dir?(Path.join(root_examples_dir, &1)))
    |> Enum.reject(&(&1 in ["demo", "shared"]))
    |> Enum.map(&String.to_atom/1)
    |> Enum.sort()
  end

  @spec metadata(atom()) :: map()
  def metadata(id) when id in @aligned_example_ids do
    family = Map.fetch!(@family_map, id)

    %{
      id: id,
      title: titleize(id),
      module: screen_module(id),
      path: :aligned,
      families: [family],
      comparable_to: nil,
      summary: "Native live_ui specialization for the root #{titleize(id)} focused example.",
      preview_id: "aligned:#{id}",
      review_artifact: "live_ui/examples/#{id}",
      package_specialization?: true,
      coverage: %{
        native?: true,
        canonical?: MapSet.member?(@canonical_review_ids, id),
        transport?: MapSet.member?(@transport_review_ids, id),
        continuity?: false,
        advanced?: family in [:data, :feedback, :operational, :overlay, :display]
      },
      runtime_obligations: %{
        server_authoritative?: true,
        direct_native?: true,
        root_example_id: id,
        canonical_review?: MapSet.member?(@canonical_review_ids, id),
        transport_review?: MapSet.member?(@transport_review_ids, id),
        continuity_review?: false,
        native_widget_kinds: native_widget_kinds(id)
      }
    }
  end

  @spec find(atom() | String.t()) :: {:ok, map()} | :error
  def find(id) when is_atom(id) or is_binary(id) do
    wanted = to_string(id)

    catalog()
    |> Enum.find(&(to_string(&1.id) == wanted))
    |> case do
      nil -> :error
      example -> {:ok, example}
    end
  end

  @spec screen_module(atom()) :: module()
  def screen_module(id) when id in @aligned_example_ids do
    Map.fetch!(@screen_modules, id)
  end

  @spec canonical_review_supported?(atom() | String.t()) :: boolean()
  def canonical_review_supported?(id) do
    Canonical.supports?(id)
  end

  @spec canonical_review_ids() :: [atom()]
  def canonical_review_ids do
    Canonical.supported_ids()
  end

  @spec canonical_element(atom() | String.t()) ::
          {:ok, UnifiedIUR.Element.t()} | {:error, term()}
  def canonical_element(id) do
    Canonical.element(id)
  end

  @spec canonical_metadata(atom() | String.t()) :: {:ok, map()} | {:error, term()}
  def canonical_metadata(id) do
    Canonical.metadata(id)
  end

  @spec titleize(atom() | String.t()) :: String.t()
  def titleize(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> titleize()
  end

  def titleize(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  @spec native_widget_kinds(atom()) :: [atom()]
  def native_widget_kinds(:alert_dialog), do: [:alert_dialog, :button, :text]
  def native_widget_kinds(:bar_chart), do: [:bar_chart]
  def native_widget_kinds(:box), do: [:box, :text]
  def native_widget_kinds(:button), do: [:button]
  def native_widget_kinds(:canvas), do: [:canvas]
  def native_widget_kinds(:checkbox), do: [:toggle]
  def native_widget_kinds(:cluster_dashboard), do: [:cluster_dashboard]
  def native_widget_kinds(:column), do: [:column, :text, :box]
  def native_widget_kinds(:command_palette), do: [:command_palette]
  def native_widget_kinds(:content), do: [:content, :text]
  def native_widget_kinds(:context_menu), do: [:context_menu]
  def native_widget_kinds(:date_input), do: [:text_input]
  def native_widget_kinds(:dialog), do: [:dialog, :button, :text]
  def native_widget_kinds(:field), do: [:field, :text_input]
  def native_widget_kinds(:field_group), do: [:field_group, :field, :text_input]
  def native_widget_kinds(:file_input), do: [:text_input]

  def native_widget_kinds(:form_builder),
    do: [:form_builder, :field_group, :field, :text_input, :button]

  def native_widget_kinds(:gauge), do: [:gauge]
  def native_widget_kinds(:grid), do: [:grid, :box, :text]
  def native_widget_kinds(:icon), do: [:icon]
  def native_widget_kinds(:image), do: [:image]
  def native_widget_kinds(:inline_feedback), do: [:inline_feedback]
  def native_widget_kinds(:label), do: [:label, :text_input]
  def native_widget_kinds(:line_chart), do: [:line_chart]
  def native_widget_kinds(:link), do: [:link]
  def native_widget_kinds(:list), do: [:list]
  def native_widget_kinds(:log_viewer), do: [:log_viewer]
  def native_widget_kinds(:markdown_viewer), do: [:markdown_viewer]
  def native_widget_kinds(:menu), do: [:menu]
  def native_widget_kinds(:numeric_input), do: [:text_input]
  def native_widget_kinds(:overlay), do: [:overlay_surface, :box, :toast, :text]
  def native_widget_kinds(:pick_list), do: [:select]
  def native_widget_kinds(:process_monitor), do: [:process_monitor]
  def native_widget_kinds(:progress), do: [:progress]
  def native_widget_kinds(:radio_group), do: [:select]
  def native_widget_kinds(:row), do: [:row, :text, :box]
  def native_widget_kinds(:scroll_bar), do: [:scroll_bar]
  def native_widget_kinds(:select), do: [:select]
  def native_widget_kinds(:separator), do: [:separator, :text]
  def native_widget_kinds(:spacer), do: [:row, :spacer, :text]
  def native_widget_kinds(:sparkline), do: [:sparkline]
  def native_widget_kinds(:split_pane), do: [:split_pane, :box, :text]
  def native_widget_kinds(:status), do: [:status]
  def native_widget_kinds(:stream_widget), do: [:stream_widget]
  def native_widget_kinds(:supervision_tree_viewer), do: [:supervision_tree_viewer]
  def native_widget_kinds(:table), do: [:table]
  def native_widget_kinds(:tabs), do: [:tabs]
  def native_widget_kinds(:text), do: [:text]
  def native_widget_kinds(:text_input), do: [:text_input]
  def native_widget_kinds(:time_input), do: [:text_input]
  def native_widget_kinds(:toast), do: [:toast, :text]
  def native_widget_kinds(:toggle), do: [:toggle]
  def native_widget_kinds(:tree_view), do: [:tree_view]
  def native_widget_kinds(:viewport), do: [:viewport, :column, :text]
end

defmodule LiveUi.Examples.Aligned.Render do
  @moduledoc false

  use Phoenix.Component

  @sample_image_uri "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='240' height='140' viewBox='0 0 240 140'><rect width='240' height='140' rx='16' fill='%23131d31'/><circle cx='58' cy='46' r='18' fill='%232563eb'/><path d='M34 114L86 62l28 28 20-20 38 44H34z' fill='%23059669'/><rect x='122' y='28' width='80' height='12' rx='6' fill='%23f9fafb' opacity='0.86'/><rect x='122' y='52' width='62' height='10' rx='5' fill='%23f9fafb' opacity='0.6'/></svg>"

  @spec render(map(), atom(), String.t()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns, example_id, title) do
    assigns =
      assigns
      |> Map.put(:example_id, example_id)
      |> Map.put(:title, title)
      |> Map.put(:id_base, "live-ui-aligned-#{example_id}")

    ~H"""
    <LiveUi.Widgets.ScreenShell.render id={@id_base} title={@title}>
      <%= preview(assigns) %>
    </LiveUi.Widgets.ScreenShell.render>
    """
  end

  defp preview(%{example_id: :text} = assigns) do
    ~H"""
    <LiveUi.Widgets.Text.render
      id={sample_id(@id_base, "text")}
      content="Text widgets carry tone through the shared live_ui theme."
      tone="accent"
    />
    """
  end

  defp preview(%{example_id: :label} = assigns) do
    ~H"""
    <LiveUi.Layout.Column.render id={sample_id(@id_base, "column")} gap="sm">
      <LiveUi.Widgets.Label.render
        id={sample_id(@id_base, "label")}
        for={sample_id(@id_base, "input")}
        content="Profile name"
      />
      <LiveUi.Widgets.TextInput.render
        id={sample_id(@id_base, "input")}
        name="profile_name"
        value="Pascal"
        placeholder="Profile name"
      />
    </LiveUi.Layout.Column.render>
    """
  end

  defp preview(%{example_id: :image} = assigns) do
    assigns = Map.put(assigns, :sample_image_uri, @sample_image_uri)

    ~H"""
    <LiveUi.Widgets.Image.render
      id={sample_id(@id_base, "image")}
      src={@sample_image_uri}
      alt="Sample dashboard artwork"
      fit="cover"
    />
    """
  end

  defp preview(%{example_id: :icon} = assigns) do
    ~H"""
    <LiveUi.Widgets.Icon.render
      id={sample_id(@id_base, "icon")}
      name="spark"
      fallback_text="spark"
      tone="accent"
    />
    """
  end

  defp preview(%{example_id: :button} = assigns) do
    ~H"""
    <LiveUi.Widgets.Button.render
      id={sample_id(@id_base, "button")}
      label="Run Widget Action"
      variant="quiet"
    />
    """
  end

  defp preview(%{example_id: :link} = assigns) do
    ~H"""
    <LiveUi.Widgets.Link.render
      id={sample_id(@id_base, "link")}
      label="Open widget docs"
      href="#"
      tone="accent"
    />
    """
  end

  defp preview(%{example_id: :separator} = assigns) do
    ~H"""
    <LiveUi.Layout.Column.render id={sample_id(@id_base, "column")} gap="sm">
      <LiveUi.Widgets.Text.render
        id={sample_id(@id_base, "top")}
        content="Primary section"
      />
      <LiveUi.Widgets.Separator.render
        id={sample_id(@id_base, "separator")}
        orientation="horizontal"
      />
      <LiveUi.Widgets.Text.render
        id={sample_id(@id_base, "bottom")}
        content="Secondary section"
      />
    </LiveUi.Layout.Column.render>
    """
  end

  defp preview(%{example_id: :spacer} = assigns) do
    ~H"""
    <LiveUi.Layout.Row.render id={sample_id(@id_base, "row")} gap="sm">
      <LiveUi.Widgets.Text.render
        id={sample_id(@id_base, "left")}
        content="Leading"
      />
      <LiveUi.Widgets.Spacer.render
        id={sample_id(@id_base, "spacer")}
        size="lg"
        grow={1}
      />
      <LiveUi.Widgets.Text.render
        id={sample_id(@id_base, "right")}
        content="Trailing"
      />
    </LiveUi.Layout.Row.render>
    """
  end

  defp preview(%{example_id: :content} = assigns) do
    ~H"""
    <LiveUi.Widgets.Content.render
      id={sample_id(@id_base, "content")}
      role="content"
    >
      <LiveUi.Widgets.Text.render
        id={sample_id(@id_base, "text")}
        content="Content wraps arbitrary body copy inside one reusable widget surface."
      />
    </LiveUi.Widgets.Content.render>
    """
  end

  defp preview(%{example_id: :box} = assigns) do
    ~H"""
    <LiveUi.Widgets.Box.render
      id={sample_id(@id_base, "box")}
      padding="lg"
      border="subtle"
      background="panel"
    >
      <LiveUi.Widgets.Text.render
        id={sample_id(@id_base, "text")}
        content="Box creates a framed panel with padding, border, and themed surface treatment."
      />
    </LiveUi.Widgets.Box.render>
    """
  end

  defp preview(%{example_id: :text_input} = assigns) do
    ~H"""
    <LiveUi.Widgets.TextInput.render
      id={sample_id(@id_base, "text-input")}
      name="widget_name"
      value="Live UI"
      placeholder="Widget name"
      variant="filled"
    />
    """
  end

  defp preview(%{example_id: :numeric_input} = assigns) do
    ~H"""
    <LiveUi.Widgets.TextInput.render
      id={sample_id(@id_base, "numeric-input")}
      name="widget_count"
      value="12"
      input_type="number"
      placeholder="Widget count"
    />
    """
  end

  defp preview(%{example_id: :date_input} = assigns) do
    ~H"""
    <LiveUi.Widgets.TextInput.render
      id={sample_id(@id_base, "date-input")}
      name="scheduled_for"
      value="2026-04-27"
      input_type="date"
    />
    """
  end

  defp preview(%{example_id: :time_input} = assigns) do
    ~H"""
    <LiveUi.Widgets.TextInput.render
      id={sample_id(@id_base, "time-input")}
      name="review_time"
      value="14:30"
      input_type="time"
    />
    """
  end

  defp preview(%{example_id: :file_input} = assigns) do
    ~H"""
    <LiveUi.Layout.Column.render id={sample_id(@id_base, "file-column")} gap="sm">
      <LiveUi.Widgets.Label.render
        id={sample_id(@id_base, "file-label")}
        for={sample_id(@id_base, "file-input")}
        content="Upload review artifact"
      />
      <LiveUi.Widgets.TextInput.render
        id={sample_id(@id_base, "file-input")}
        name="artifact"
        input_type="file"
      />
    </LiveUi.Layout.Column.render>
    """
  end

  defp preview(%{example_id: :toggle} = assigns) do
    ~H"""
    <LiveUi.Widgets.Toggle.render
      id={sample_id(@id_base, "toggle")}
      name="widget_enabled"
      checked={true}
    />
    """
  end

  defp preview(%{example_id: :checkbox} = assigns) do
    ~H"""
    <LiveUi.Layout.Row.render id={sample_id(@id_base, "checkbox-row")} gap="sm" align="center">
      <LiveUi.Widgets.Toggle.render
        id={sample_id(@id_base, "checkbox")}
        name="include_transport"
        checked={true}
      />
      <LiveUi.Widgets.Text.render
        id={sample_id(@id_base, "checkbox-label")}
        content="Include transport review"
      />
    </LiveUi.Layout.Row.render>
    """
  end

  defp preview(%{example_id: :select} = assigns) do
    ~H"""
    <LiveUi.Widgets.Select.render
      id={sample_id(@id_base, "select")}
      name="widget_category"
      options={[
        %{value: "foundational", label: "Foundational"},
        %{value: "display", label: "Display", selected: true},
        %{value: "overlay", label: "Overlay"}
      ]}
    />
    """
  end

  defp preview(%{example_id: :pick_list} = assigns) do
    ~H"""
    <LiveUi.Widgets.Select.render
      id={sample_id(@id_base, "pick-list")}
      name="review_modes"
      multiple={true}
      options={[
        %{value: "native", label: "Native", selected: true},
        %{value: "canonical", label: "Canonical", selected: true},
        %{value: "transport", label: "Transport"}
      ]}
    />
    """
  end

  defp preview(%{example_id: :radio_group} = assigns) do
    ~H"""
    <LiveUi.Widgets.Select.render
      id={sample_id(@id_base, "radio-group")}
      name="active_lane"
      options={[
        %{value: "native", label: "Native", selected: true},
        %{value: "canonical", label: "Canonical"},
        %{value: "transport", label: "Transport"}
      ]}
    />
    """
  end

  defp preview(%{example_id: :field} = assigns) do
    ~H"""
    <LiveUi.Forms.Field.render id={sample_id(@id_base, "field")} name="owner">
      <:label>Owner</:label>
      <:control>
        <LiveUi.Widgets.TextInput.render
          id={sample_id(@id_base, "field-input")}
          name="owner"
          value="Pascal"
        />
      </:control>
      <:help>
        <LiveUi.Widgets.Text.render
          id={sample_id(@id_base, "field-help")}
          content="Field binds one label, one control, and optional help text."
        />
      </:help>
    </LiveUi.Forms.Field.render>
    """
  end

  defp preview(%{example_id: :field_group} = assigns) do
    ~H"""
    <LiveUi.Forms.FieldGroup.render
      id={sample_id(@id_base, "field-group")}
      legend="Reviewer Identity"
    >
      <LiveUi.Forms.Field.render id={sample_id(@id_base, "name-field")} name="name">
        <:label>Name</:label>
        <:control>
          <LiveUi.Widgets.TextInput.render
            id={sample_id(@id_base, "name-input")}
            name="name"
            value="Pascal"
          />
        </:control>
      </LiveUi.Forms.Field.render>
      <LiveUi.Forms.Field.render id={sample_id(@id_base, "role-field")} name="role">
        <:label>Role</:label>
        <:control>
          <LiveUi.Widgets.TextInput.render
            id={sample_id(@id_base, "role-input")}
            name="role"
            value="Maintainer"
          />
        </:control>
      </LiveUi.Forms.Field.render>
    </LiveUi.Forms.FieldGroup.render>
    """
  end

  defp preview(%{example_id: :form_builder} = assigns) do
    ~H"""
    <LiveUi.Forms.FormBuilder.render id={sample_id(@id_base, "form")}>
      <LiveUi.Forms.FieldGroup.render
        id={sample_id(@id_base, "group")}
        legend="Review Details"
      >
        <LiveUi.Forms.Field.render id={sample_id(@id_base, "field")} name="summary">
          <:label>Summary</:label>
          <:control>
            <LiveUi.Widgets.TextInput.render
              id={sample_id(@id_base, "summary-input")}
              name="summary"
              value="Align focused examples"
            />
          </:control>
        </LiveUi.Forms.Field.render>
      </LiveUi.Forms.FieldGroup.render>
      <LiveUi.Widgets.Button.render
        id={sample_id(@id_base, "submit")}
        label="Save Review"
      />
    </LiveUi.Forms.FormBuilder.render>
    """
  end

  defp preview(%{example_id: :row} = assigns) do
    ~H"""
    <LiveUi.Layout.Row.render id={sample_id(@id_base, "row")} gap="md" align="center">
      <LiveUi.Widgets.Box.render
        id={sample_id(@id_base, "row-box-left")}
        padding="sm"
        border="subtle"
      >
        <LiveUi.Widgets.Text.render id={sample_id(@id_base, "row-text-left")} content="Left" />
      </LiveUi.Widgets.Box.render>
      <LiveUi.Widgets.Box.render
        id={sample_id(@id_base, "row-box-right")}
        padding="sm"
        border="subtle"
      >
        <LiveUi.Widgets.Text.render id={sample_id(@id_base, "row-text-right")} content="Right" />
      </LiveUi.Widgets.Box.render>
    </LiveUi.Layout.Row.render>
    """
  end

  defp preview(%{example_id: :column} = assigns) do
    ~H"""
    <LiveUi.Layout.Column.render id={sample_id(@id_base, "column")} gap="sm">
      <LiveUi.Widgets.Box.render
        id={sample_id(@id_base, "column-box-top")}
        padding="sm"
        border="subtle"
      >
        <LiveUi.Widgets.Text.render id={sample_id(@id_base, "column-text-top")} content="Top" />
      </LiveUi.Widgets.Box.render>
      <LiveUi.Widgets.Box.render
        id={sample_id(@id_base, "column-box-bottom")}
        padding="sm"
        border="subtle"
      >
        <LiveUi.Widgets.Text.render
          id={sample_id(@id_base, "column-text-bottom")}
          content="Bottom"
        />
      </LiveUi.Widgets.Box.render>
    </LiveUi.Layout.Column.render>
    """
  end

  defp preview(%{example_id: :grid} = assigns) do
    ~H"""
    <LiveUi.Layout.Grid.render id={sample_id(@id_base, "grid")} columns={2} gap="md">
      <LiveUi.Widgets.Box.render
        id={sample_id(@id_base, "grid-a")}
        padding="sm"
        border="subtle"
      >
        <LiveUi.Widgets.Text.render id={sample_id(@id_base, "grid-a-text")} content="A" />
      </LiveUi.Widgets.Box.render>
      <LiveUi.Widgets.Box.render
        id={sample_id(@id_base, "grid-b")}
        padding="sm"
        border="subtle"
      >
        <LiveUi.Widgets.Text.render id={sample_id(@id_base, "grid-b-text")} content="B" />
      </LiveUi.Widgets.Box.render>
      <LiveUi.Widgets.Box.render
        id={sample_id(@id_base, "grid-c")}
        padding="sm"
        border="subtle"
      >
        <LiveUi.Widgets.Text.render id={sample_id(@id_base, "grid-c-text")} content="C" />
      </LiveUi.Widgets.Box.render>
      <LiveUi.Widgets.Box.render
        id={sample_id(@id_base, "grid-d")}
        padding="sm"
        border="subtle"
      >
        <LiveUi.Widgets.Text.render id={sample_id(@id_base, "grid-d-text")} content="D" />
      </LiveUi.Widgets.Box.render>
    </LiveUi.Layout.Grid.render>
    """
  end

  defp preview(%{example_id: :menu} = assigns) do
    ~H"""
    <LiveUi.Widgets.Menu.render
      id={sample_id(@id_base, "menu")}
      orientation="vertical"
      active_item="insights"
      items={[
        %{id: "overview", label: "Overview"},
        %{id: "insights", label: "Insights"},
        %{id: "settings", label: "Settings"}
      ]}
    />
    """
  end

  defp preview(%{example_id: :tabs} = assigns) do
    ~H"""
    <LiveUi.Widgets.Tabs.render
      id={sample_id(@id_base, "tabs")}
      active_item="surface"
      items={[
        %{id: "surface", label: "Surface"},
        %{id: "state", label: "State"},
        %{id: "signals", label: "Signals"}
      ]}
    />
    """
  end

  defp preview(%{example_id: :command_palette} = assigns) do
    ~H"""
    <LiveUi.Widgets.CommandPalette.render
      id={sample_id(@id_base, "command-palette")}
      query="wid"
      items={[
        %{id: "widgets", label: "Open widgets", active: true},
        %{id: "workspace", label: "Toggle workspace"},
        %{id: "validate", label: "Run validation"}
      ]}
    />
    """
  end

  defp preview(%{example_id: :list} = assigns) do
    ~H"""
    <LiveUi.Widgets.List.render
      id={sample_id(@id_base, "list")}
      selection_mode="single"
      items={[
        %{id: "button", label: "Button", description: "Primary action surface", selected: true},
        %{id: "tabs", label: "Tabs", description: "Section navigation"},
        %{id: "toast", label: "Toast", description: "Transient feedback"}
      ]}
    />
    """
  end

  defp preview(%{example_id: :table} = assigns) do
    ~H"""
    <LiveUi.Widgets.Table.render
      id={sample_id(@id_base, "table")}
      columns={[
        %{id: "widget", label: "Widget"},
        %{id: "family", label: "Family"},
        %{id: "events", label: "Events"}
      ]}
      rows={[
        %{id: "button", cells: ["Button", "Content", "Click"]},
        %{id: "tabs", cells: ["Tabs", "Navigation", "Navigate"]},
        %{id: "toast", cells: ["Toast", "Overlay", "None"]}
      ]}
    />
    """
  end

  defp preview(%{example_id: :tree_view} = assigns) do
    ~H"""
    <LiveUi.Widgets.TreeView.render
      id={sample_id(@id_base, "tree-view")}
      nodes={[
        %{
          id: "widgets",
          label: "Widgets",
          expanded: true,
          children: [
            %{id: "content", label: "Content"},
            %{id: "overlay", label: "Overlay", selected: true}
          ]
        }
      ]}
    />
    """
  end

  defp preview(%{example_id: :markdown_viewer} = assigns) do
    ~H"""
    <LiveUi.Widgets.MarkdownViewer.render
      id={sample_id(@id_base, "markdown")}
      source={"# Widget Notes\n\n- Built with `live_ui`\n- Styled through the shared theme\n- Rendered as a static preview"}
      mode="rendered"
    />
    """
  end

  defp preview(%{example_id: :log_viewer} = assigns) do
    ~H"""
    <LiveUi.Widgets.LogViewer.render
      id={sample_id(@id_base, "log-viewer")}
      entries={[
        %{id: "1", timestamp: "10:41:02", severity: "info", message: "Mounted widget preview"},
        %{id: "2", timestamp: "10:41:04", severity: "success", message: "Resolved style profile"},
        %{id: "3", timestamp: "10:41:06", severity: "warning", message: "No event handlers attached"}
      ]}
    />
    """
  end

  defp preview(%{example_id: :status} = assigns) do
    ~H"""
    <LiveUi.Widgets.Status.render
      id={sample_id(@id_base, "status")}
      text="Ready for review"
      severity="success"
      status="healthy"
    />
    """
  end

  defp preview(%{example_id: :progress} = assigns) do
    ~H"""
    <LiveUi.Widgets.Progress.render
      id={sample_id(@id_base, "progress")}
      current={68}
      total={100}
      label="Widget coverage"
    />
    """
  end

  defp preview(%{example_id: :gauge} = assigns) do
    ~H"""
    <LiveUi.Widgets.Gauge.render
      id={sample_id(@id_base, "gauge")}
      value={72}
      min={0}
      max={100}
      label="Health"
    />
    """
  end

  defp preview(%{example_id: :inline_feedback} = assigns) do
    ~H"""
    <LiveUi.Widgets.InlineFeedback.render
      id={sample_id(@id_base, "inline-feedback")}
      title="Heads up"
      message="This widget preview is intentionally static."
      severity="info"
    />
    """
  end

  defp preview(%{example_id: :sparkline} = assigns) do
    ~H"""
    <LiveUi.Widgets.Sparkline.render
      id={sample_id(@id_base, "sparkline")}
      series={[4, 6, 5, 8, 9, 7]}
    />
    """
  end

  defp preview(%{example_id: :bar_chart} = assigns) do
    ~H"""
    <LiveUi.Widgets.BarChart.render
      id={sample_id(@id_base, "bar-chart")}
      series={[%{label: "A", value: 4}, %{label: "B", value: 8}, %{label: "C", value: 6}]}
    />
    """
  end

  defp preview(%{example_id: :line_chart} = assigns) do
    ~H"""
    <LiveUi.Widgets.LineChart.render
      id={sample_id(@id_base, "line-chart")}
      series={[%{x: 1, y: 2}, %{x: 2, y: 5}, %{x: 3, y: 4}, %{x: 4, y: 8}]}
    />
    """
  end

  defp preview(%{example_id: :stream_widget} = assigns) do
    ~H"""
    <LiveUi.Widgets.StreamWidget.render
      id={sample_id(@id_base, "stream-widget")}
      ordering="append_only"
      entries={[
        %{id: "1", severity: "info", message: "Preview mounted"},
        %{id: "2", severity: "success", message: "Theme resolved"},
        %{id: "3", severity: "warning", message: "Static mode enabled"}
      ]}
    />
    """
  end

  defp preview(%{example_id: :process_monitor} = assigns) do
    ~H"""
    <LiveUi.Widgets.ProcessMonitor.render
      id={sample_id(@id_base, "process-monitor")}
      processes={[
        %{id: "ui", pid: "#PID<0.321.0>", state: :running},
        %{id: "theme", pid: "#PID<0.322.0>", state: :idle},
        %{id: "preview", pid: "#PID<0.323.0>", state: :waiting}
      ]}
    />
    """
  end

  defp preview(%{example_id: :supervision_tree_viewer} = assigns) do
    ~H"""
    <LiveUi.Widgets.SupervisionTreeViewer.render
      id={sample_id(@id_base, "supervision-tree")}
      expanded={true}
      nodes={[
        %{
          id: "root",
          label: "LiveUi.Examples.Supervisor",
          type: "supervisor",
          status: "up",
          children: [
            %{id: "server", label: "PreviewServer", type: "worker", status: "up"},
            %{id: "theme", label: "ThemeCache", type: "worker", status: "up"}
          ]
        }
      ]}
    />
    """
  end

  defp preview(%{example_id: :cluster_dashboard} = assigns) do
    ~H"""
    <LiveUi.Widgets.ClusterDashboard.render
      id={sample_id(@id_base, "cluster-dashboard")}
      summary={%{healthy: 2, degraded: 1}}
      nodes={[
        %{id: "node-a", status: "healthy"},
        %{id: "node-b", status: "healthy"},
        %{id: "node-c", status: "degraded"}
      ]}
    />
    """
  end

  defp preview(%{example_id: :overlay} = assigns) do
    ~H"""
    <LiveUi.Widgets.OverlaySurface.render
      id={sample_id(@id_base, "overlay")}
      mode="stacked"
      background_fill="transparent"
      dismissible={false}
    >
      <:base>
        <LiveUi.Widgets.Box.render
          id={sample_id(@id_base, "overlay-base")}
          padding="md"
          border="subtle"
          background="panel"
        >
          <LiveUi.Widgets.Text.render
            id={sample_id(@id_base, "overlay-base-text")}
            content="Base workspace content"
          />
        </LiveUi.Widgets.Box.render>
      </:base>
      <:overlay>
        <LiveUi.Widgets.Toast.render
          id={sample_id(@id_base, "overlay-toast")}
          severity="info"
          state="active"
          open={true}
          placement="top-end"
          duration_ms={3000}
        >
          <LiveUi.Widgets.Text.render
            id={sample_id(@id_base, "overlay-toast-text")}
            content="Overlay surfaces can present layered feedback."
          />
        </LiveUi.Widgets.Toast.render>
      </:overlay>
    </LiveUi.Widgets.OverlaySurface.render>
    """
  end

  defp preview(%{example_id: :dialog} = assigns) do
    ~H"""
    <LiveUi.Widgets.Dialog.render
      id={sample_id(@id_base, "dialog")}
      title="Review widget changes"
      open={true}
      modal={false}
      dismissible={true}
      size="md"
      background_fill="transparent"
    >
      <LiveUi.Widgets.Text.render
        id={sample_id(@id_base, "dialog-text")}
        content="Dialogs group content and actions inside a focused overlay surface."
      />
      <:actions>
        <LiveUi.Widgets.Button.render
          id={sample_id(@id_base, "dialog-action")}
          label="Dismiss"
          variant="quiet"
        />
      </:actions>
    </LiveUi.Widgets.Dialog.render>
    """
  end

  defp preview(%{example_id: :alert_dialog} = assigns) do
    ~H"""
    <LiveUi.Widgets.AlertDialog.render
      id={sample_id(@id_base, "alert-dialog")}
      title="Delete preview?"
      severity="warning"
      open={true}
      requires_confirmation={true}
      background_fill="transparent"
    >
      <LiveUi.Widgets.Text.render
        id={sample_id(@id_base, "alert-dialog-text")}
        content="Alert dialogs emphasize sensitive actions that need confirmation."
      />
      <:actions>
        <LiveUi.Widgets.Button.render
          id={sample_id(@id_base, "alert-dialog-action")}
          label="Keep widget"
          variant="quiet"
        />
      </:actions>
    </LiveUi.Widgets.AlertDialog.render>
    """
  end

  defp preview(%{example_id: :context_menu} = assigns) do
    ~H"""
    <LiveUi.Widgets.ContextMenu.render
      id={sample_id(@id_base, "context-menu")}
      open={true}
      placement="bottom-start"
      active_item="duplicate"
      anchor={%{x: 24, y: 12}}
      items={[
        %{id: "open", label: "Open"},
        %{id: "duplicate", label: "Duplicate"},
        %{id: "archive", label: "Archive"}
      ]}
    />
    """
  end

  defp preview(%{example_id: :toast} = assigns) do
    ~H"""
    <LiveUi.Widgets.Toast.render
      id={sample_id(@id_base, "toast")}
      open={true}
      placement="top-end"
      duration_ms={3000}
      severity="success"
      state="active"
    >
      <LiveUi.Widgets.Text.render
        id={sample_id(@id_base, "toast-text")}
        content="Widget preview saved"
      />
    </LiveUi.Widgets.Toast.render>
    """
  end

  defp preview(%{example_id: :viewport} = assigns) do
    ~H"""
    <LiveUi.Widgets.Viewport.render
      id={sample_id(@id_base, "viewport")}
      axis="vertical"
      offset_y={12}
      scrollbars="auto"
      width="100%"
      height="12rem"
    >
      <LiveUi.Layout.Column.render id={sample_id(@id_base, "viewport-column")} gap="sm">
        <%= for index <- 1..6 do %>
          <LiveUi.Widgets.Text.render
            id={sample_id(@id_base, "viewport-line-#{index}")}
            content={"Viewport row #{index}"}
          />
        <% end %>
      </LiveUi.Layout.Column.render>
    </LiveUi.Widgets.Viewport.render>
    """
  end

  defp preview(%{example_id: :scroll_bar} = assigns) do
    ~H"""
    <LiveUi.Widgets.ScrollBar.render
      id={sample_id(@id_base, "scroll-bar")}
      orientation="vertical"
      position_start={0.15}
      position_end={0.55}
      viewport_size={240}
      content_size={720}
      viewport_ref="preview-viewport"
    />
    """
  end

  defp preview(%{example_id: :split_pane} = assigns) do
    ~H"""
    <LiveUi.Widgets.SplitPane.render
      id={sample_id(@id_base, "split-pane")}
      direction="horizontal"
      ratio={0.45}
      resizable={true}
    >
      <:primary>
        <LiveUi.Widgets.Box.render
          id={sample_id(@id_base, "split-primary")}
          padding="md"
          border="subtle"
          background="panel"
        >
          <LiveUi.Widgets.Text.render
            id={sample_id(@id_base, "split-primary-text")}
            content="Primary pane"
          />
        </LiveUi.Widgets.Box.render>
      </:primary>
      <:secondary>
        <LiveUi.Widgets.Box.render
          id={sample_id(@id_base, "split-secondary")}
          padding="md"
          border="subtle"
          background="panel"
        >
          <LiveUi.Widgets.Text.render
            id={sample_id(@id_base, "split-secondary-text")}
            content="Secondary pane"
          />
        </LiveUi.Widgets.Box.render>
      </:secondary>
    </LiveUi.Widgets.SplitPane.render>
    """
  end

  defp preview(%{example_id: :canvas} = assigns) do
    ~H"""
    <LiveUi.Widgets.Canvas.render
      id={sample_id(@id_base, "canvas")}
      width={48}
      height={12}
      unit="cell"
      background="analysis"
      operations={[
        %{kind: "text", position: %{x: 2, y: 2}, text: "Live UI"},
        %{kind: "text", position: %{x: 2, y: 5}, text: "Canvas preview"},
        %{kind: "text", position: %{x: 2, y: 8}, text: "48 x 12 cells"}
      ]}
    />
    """
  end

  defp sample_id(base, suffix), do: "#{base}-#{suffix}"
end

for example_id <- aligned_example_ids do
  title = LiveUi.Examples.Aligned.titleize(example_id)

  module_name =
    example_id
    |> Atom.to_string()
    |> Macro.camelize()
    |> then(&Module.concat(LiveUi.Examples.Aligned, &1))

  Module.create(
    module_name,
    quote do
      @moduledoc false

      use LiveUi.Screen,
        id: unquote(Macro.escape(example_id)),
        title: unquote(title)

      @impl true
      def render(assigns) do
        LiveUi.Examples.Aligned.Render.render(assigns, id(), title())
      end

      @impl true
      def metadata do
        LiveUi.Examples.Aligned.metadata(id())
        |> Map.put(:module, __MODULE__)
        |> Map.put(:kind, :aligned_native_example)
      end
    end,
    Macro.Env.location(__ENV__)
  )
end
