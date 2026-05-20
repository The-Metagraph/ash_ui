defmodule DesktopUi.Widgets do
  @moduledoc """
  Package-facing entrypoint for native `desktop_ui` widgets.
  """

  alias DesktopUi.Widget
  alias DesktopUi.Widgets.{Builder, Data, Feedback, Foundational, Input, Navigation}
  alias DesktopUi.Widgets.{Operational, Visualization}

  @spec families() :: [Widget.family()]
  def families do
    kinds()
    |> Enum.map(&Widget.family_for/1)
    |> Enum.uniq()
    |> Enum.sort_by(&to_string/1)
  end

  @spec modules() :: [module()]
  def modules do
    [
      __MODULE__,
      Widget,
      Builder,
      Foundational,
      Input,
      Navigation,
      Data,
      Feedback,
      Visualization,
      Operational
    ]
  end

  @spec kinds() :: [atom()]
  def kinds do
    [
      Foundational.kinds(),
      Input.kinds(),
      Navigation.kinds(),
      Data.kinds(),
      Feedback.kinds(),
      Visualization.kinds(),
      Operational.kinds(),
      [:column, :row, :sparkline, :stack, :status, :window]
    ]
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.sort()
  end

  @spec family_for_kind(atom() | String.t()) :: Widget.family()
  def family_for_kind(kind) when is_binary(kind),
    do: kind |> String.to_atom() |> family_for_kind()

  def family_for_kind(kind), do: Widget.family_for(kind)

  @spec validation_state() :: map()
  def validation_state do
    %{
      widget_contract: :ready,
      registration_surface: :ready,
      direct_native_scaffold: :ready,
      foundational_content_widgets: :ready,
      foundational_action_widgets: :ready,
      foundational_form_widgets: :ready,
      foundational_navigation_widgets: :ready,
      focus_metadata: :ready,
      shortcut_metadata: :ready,
      advanced_data_widgets: :ready,
      advanced_feedback_widgets: :ready,
      advanced_visualization_widgets: :ready,
      advanced_operational_widgets: :ready,
      advanced_window_metadata: :ready,
      slot_contracts: :ready,
      style_contracts: :ready
    }
  end

  @spec registration_model() :: map()
  def registration_model do
    %{
      builder: Builder,
      direct_native_only: true,
      canonical_branching: false,
      supported_kinds: kinds(),
      supported_families: families(),
      shared_focus_model: true,
      multiwindow_metadata: true
    }
  end

  @spec window(String.t() | atom(), String.t(), [Widget.t()], keyword()) :: Widget.t()
  def window(id, title, children \\ [], opts \\ []) do
    Builder.window(id, title, children, opts)
  end

  @spec dialog(String.t() | atom(), String.t(), [Widget.t()], keyword()) :: Widget.t()
  def dialog(id, title, children \\ [], opts \\ []) do
    Builder.dialog(id, title, children, opts)
  end

  @spec content(String.t() | atom(), [Widget.t()], keyword()) :: Widget.t()
  def content(id, children \\ [], opts \\ []) do
    Foundational.content(id, children, opts)
  end

  @spec column(String.t() | atom(), [Widget.t()], keyword()) :: Widget.t()
  def column(id, children \\ [], opts \\ []) do
    Builder.column(id, children, opts)
  end

  @spec row(String.t() | atom(), [Widget.t()], keyword()) :: Widget.t()
  def row(id, children \\ [], opts \\ []) do
    Builder.row(id, children, opts)
  end

  @spec stack(String.t() | atom(), [Widget.t()], keyword()) :: Widget.t()
  def stack(id, children \\ [], opts \\ []) do
    Builder.stack(id, children, opts)
  end

  @spec text(String.t() | atom(), String.t(), keyword()) :: Widget.t()
  def text(id, content, opts \\ []) do
    Foundational.text(id, content, opts)
  end

  @spec label(String.t() | atom(), String.t(), keyword()) :: Widget.t()
  def label(id, content, opts \\ []) do
    Foundational.label(id, content, opts)
  end

  @spec icon(String.t() | atom(), atom() | String.t(), keyword()) :: Widget.t()
  def icon(id, name, opts \\ []) do
    Foundational.icon(id, name, opts)
  end

  @spec image(String.t() | atom(), String.t(), keyword()) :: Widget.t()
  def image(id, source, opts \\ []) do
    Foundational.image(id, source, opts)
  end

  @spec badge(String.t() | atom(), String.t(), keyword()) :: Widget.t()
  def badge(id, content, opts \\ []) do
    Foundational.badge(id, content, opts)
  end

  @spec hero(String.t() | atom(), String.t(), keyword()) :: Widget.t()
  def hero(id, headline, opts \\ []) do
    Foundational.hero(id, headline, opts)
  end

  @spec spacer(String.t() | atom(), keyword()) :: Widget.t()
  def spacer(id, opts \\ []) do
    Foundational.spacer(id, opts)
  end

  @spec separator(String.t() | atom(), keyword()) :: Widget.t()
  def separator(id, opts \\ []) do
    Foundational.separator(id, opts)
  end

  @spec button(String.t() | atom(), String.t(), keyword()) :: Widget.t()
  def button(id, label, opts \\ []) do
    Foundational.button(id, label, opts)
  end

  @spec toggle(String.t() | atom(), String.t(), keyword()) :: Widget.t()
  def toggle(id, label, opts \\ []) do
    Foundational.toggle(id, label, opts)
  end

  @spec link(String.t() | atom(), String.t(), String.t(), keyword()) :: Widget.t()
  def link(id, label, href, opts \\ []) do
    Foundational.link(id, label, href, opts)
  end

  @spec command(String.t() | atom(), String.t(), keyword()) :: Widget.t()
  def command(id, label, opts \\ []) do
    Foundational.command(id, label, opts)
  end

  @spec text_input(String.t() | atom(), keyword()) :: Widget.t()
  def text_input(id, opts \\ []) do
    Input.text_input(id, opts)
  end

  @spec numeric_input(String.t() | atom(), keyword()) :: Widget.t()
  def numeric_input(id, opts \\ []) do
    Input.numeric_input(id, opts)
  end

  @spec slider(String.t() | atom(), keyword()) :: Widget.t()
  def slider(id, opts \\ []) do
    Input.slider(id, opts)
  end

  @spec date_input(String.t() | atom(), keyword()) :: Widget.t()
  def date_input(id, opts \\ []) do
    Input.date_input(id, opts)
  end

  @spec time_input(String.t() | atom(), keyword()) :: Widget.t()
  def time_input(id, opts \\ []) do
    Input.time_input(id, opts)
  end

  @spec file_input(String.t() | atom(), keyword()) :: Widget.t()
  def file_input(id, opts \\ []) do
    Input.file_input(id, opts)
  end

  @spec pick_list(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def pick_list(id, options, opts \\ []) do
    Input.pick_list(id, options, opts)
  end

  @spec checkbox(String.t() | atom(), String.t(), keyword()) :: Widget.t()
  def checkbox(id, label, opts \\ []) do
    Input.checkbox(id, label, opts)
  end

  @spec radio_group(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def radio_group(id, options, opts \\ []) do
    Input.radio_group(id, options, opts)
  end

  @spec select(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def select(id, options, opts \\ []) do
    Input.select(id, options, opts)
  end

  @spec tabs(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def tabs(id, items, opts \\ []) do
    Navigation.tabs(id, items, opts)
  end

  @spec menu(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def menu(id, items, opts \\ []) do
    Navigation.menu(id, items, opts)
  end

  @spec breadcrumbs(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def breadcrumbs(id, items, opts \\ []) do
    Navigation.breadcrumbs(id, items, opts)
  end

  @spec list(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def list(id, items, opts \\ []) do
    Navigation.list(id, items, opts)
  end

  @spec context_selector(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def context_selector(id, groups, opts \\ []) do
    Navigation.context_selector(id, groups, opts)
  end

  @spec file_tree_browser(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def file_tree_browser(id, nodes, opts \\ []) do
    Navigation.file_tree_browser(id, nodes, opts)
  end

  @spec status(String.t() | atom(), String.t(), keyword()) :: Widget.t()
  def status(id, label, opts \\ []) do
    Builder.status(id, label, opts)
  end

  @spec table(String.t() | atom(), [map() | keyword()], [map() | keyword()], keyword()) ::
          Widget.t()
  def table(id, columns, rows, opts \\ []) do
    Data.table(id, columns, rows, opts)
  end

  @spec tree_view(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def tree_view(id, nodes, opts \\ []) do
    Data.tree_view(id, nodes, opts)
  end

  @spec stat(String.t() | atom(), keyword()) :: Widget.t()
  def stat(id, opts \\ []) do
    Data.stat(id, opts)
  end

  @spec key_value(String.t() | atom(), keyword()) :: Widget.t()
  def key_value(id, opts \\ []) do
    Data.key_value(id, opts)
  end

  @spec info_list(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def info_list(id, items, opts \\ []) do
    Data.info_list(id, items, opts)
  end

  @spec inspector(String.t() | atom(), map() | keyword(), keyword()) :: Widget.t()
  def inspector(id, subject, opts \\ []) do
    Data.inspector(id, subject, opts)
  end

  @spec markdown_viewer(String.t() | atom(), String.t(), keyword()) :: Widget.t()
  def markdown_viewer(id, markdown, opts \\ []) do
    Data.markdown_viewer(id, markdown, opts)
  end

  @spec toast(String.t() | atom(), String.t(), keyword()) :: Widget.t()
  def toast(id, message, opts \\ []) do
    Feedback.toast(id, message, opts)
  end

  @spec inline_feedback(String.t() | atom(), keyword()) :: Widget.t()
  def inline_feedback(id, opts \\ []) do
    Feedback.inline_feedback(id, opts)
  end

  @spec alert_dialog(String.t() | atom(), String.t(), [Widget.t()], keyword()) :: Widget.t()
  def alert_dialog(id, message, children, opts \\ []) do
    Feedback.alert_dialog(id, message, children, opts)
  end

  @spec progress(String.t() | atom(), keyword()) :: Widget.t()
  def progress(id, opts \\ []) do
    Feedback.progress(id, opts)
  end

  @spec diff_banner(String.t() | atom(), keyword()) :: Widget.t()
  def diff_banner(id, opts \\ []) do
    Feedback.diff_banner(id, opts)
  end

  @spec sparkline(String.t() | atom(), keyword()) :: Widget.t()
  def sparkline(id, opts \\ []) do
    Feedback.sparkline(id, opts)
  end

  @spec gauge(String.t() | atom(), keyword()) :: Widget.t()
  def gauge(id, opts \\ []) do
    Visualization.gauge(id, opts)
  end

  @spec bar_chart(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def bar_chart(id, series, opts \\ []) do
    Visualization.bar_chart(id, series, opts)
  end

  @spec line_chart(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def line_chart(id, series, opts \\ []) do
    Visualization.line_chart(id, series, opts)
  end

  @spec timeline(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def timeline(id, items, opts \\ []) do
    Visualization.timeline(id, items, opts)
  end

  @spec canvas(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def canvas(id, operations, opts \\ []) do
    Visualization.canvas(id, operations, opts)
  end

  @spec log_viewer(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def log_viewer(id, entries, opts \\ []) do
    Operational.log_viewer(id, entries, opts)
  end

  @spec cluster_dashboard(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def cluster_dashboard(id, nodes, opts \\ []) do
    Operational.cluster_dashboard(id, nodes, opts)
  end

  @spec command_palette(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def command_palette(id, commands, opts \\ []) do
    Operational.command_palette(id, commands, opts)
  end

  @spec stream_widget(String.t() | atom(), keyword()) :: Widget.t()
  def stream_widget(id, opts \\ []) do
    Operational.stream_widget(id, opts)
  end

  @spec supervision_tree_viewer(String.t() | atom(), keyword()) :: Widget.t()
  def supervision_tree_viewer(id, opts \\ []) do
    Operational.supervision_tree_viewer(id, opts)
  end

  @spec process_monitor(String.t() | atom(), [map() | keyword()], keyword()) :: Widget.t()
  def process_monitor(id, processes, opts \\ []) do
    Operational.process_monitor(id, processes, opts)
  end

  @spec window_command(String.t() | atom(), String.t(), keyword()) :: Widget.t()
  def window_command(id, label, opts \\ []) do
    Operational.window_command(id, label, opts)
  end
end
