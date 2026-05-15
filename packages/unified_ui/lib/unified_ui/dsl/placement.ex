defmodule UnifiedUi.Dsl.Placement do
  @moduledoc """
  Baseline section-boundary and placement rules for authored `UnifiedUi` modules.
  """

  @section_boundaries %{
    identity: [:id, :title, :description, :authored_ref, :annotations, :tags],
    composition: [:root, :mode, :summary, :default_slot],
    themes: [:default_theme, :inherit?, :summary],
    signals: [:namespace, :default_target, :mode]
  }

  @placement_rules [
    %{
      id: :required_identity_and_composition_sections,
      description:
        "Authored modules must declare identity and composition sections before higher-level constructs are added."
    },
    %{
      id: :root_identifier_must_differ_from_module_identifier,
      description:
        "The composition root identifier must not duplicate the module identity identifier."
    },
    %{
      id: :default_slot_requires_fragment_mode,
      description:
        "A default slot may only be declared when the authored composition mode is :fragment."
    },
    %{
      id: :field_requires_one_input_child,
      description:
        "Field composition nodes must contain exactly one child and that child must be an input control."
    },
    %{
      id: :leaf_nodes_cannot_have_children,
      description:
        "Leaf widget and navigation nodes may not declare nested children in the authored Phase 2 surface."
    },
    %{
      id: :overlay_content_refs_must_resolve,
      description:
        "Dialogs, context menus, scroll bars, and split panes must reference existing authored nodes so advanced flows remain deterministic."
    },
    %{
      id: :split_pane_refs_must_be_distinct,
      description:
        "Split panes must reference two distinct authored nodes so multi-pane composition remains unambiguous."
    },
    %{
      id: :layer_refs_must_target_overlay_nodes,
      description:
        "Overlay stacks must reference authored overlay nodes only so layered composition remains explicit."
    },
    %{
      id: :viewport_and_scroll_refs_must_target_displayable_content,
      description:
        "Viewport and scroll-region declarations must target authored content nodes rather than overlay-only nodes."
    },
    %{
      id: :canvas_operations_require_kind_and_position,
      description:
        "Canvas operations must declare a supported kind and positioned coordinate metadata so direct drawing remains portable."
    }
  ]

  @leaf_kinds [
    :text,
    :label,
    :icon,
    :image,
    :button,
    :link,
    :separator,
    :spacer,
    :text_input,
    :numeric_input,
    :toggle,
    :checkbox,
    :radio_group,
    :select,
    :pick_list,
    :date_input,
    :time_input,
    :file_input,
    :menu,
    :tabs,
    :command_palette,
    :inline_rich_text_heading,
    :kicker,
    :avatar,
    :presence_dot,
    :unread_badge,
    :segmented_button_group,
    :runtime_form_shell,
    :sidebar_item,
    :pipeline_stepper_horizontal,
    :segmented_progress_bar,
    :workflow_stage_list_vertical,
    :meter_thin,
    :redline_inline,
    :code_block_syntax_highlighted
  ]

  @advanced_leaf_kinds [
    :list,
    :table,
    :tree_view,
    :markdown_viewer,
    :log_viewer,
    :status,
    :progress,
    :gauge,
    :inline_feedback,
    :sparkline,
    :bar_chart,
    :line_chart,
    :stream_widget,
    :process_monitor,
    :supervision_tree_viewer,
    :cluster_dashboard,
    :context_menu,
    :dialog,
    :alert_dialog,
    :toast,
    :scroll_bar,
    :split_pane
  ]

  @layout_kinds [:box, :row, :column, :grid, :stack]
  @container_kinds [
    :content,
    :form_builder,
    :field_group,
    :disclosure,
    :chat_composer,
    :list_item_multi_column,
    :artifact_row,
    :sidebar_shell,
    :sidebar_section,
    :sticky_frosted_header,
    :slide_over_panel,
    :event_callout,
    :list_repeat
  ]

  @spec section_boundaries() :: %{atom() => [atom()]}
  def section_boundaries do
    @section_boundaries
  end

  @spec placement_rules() :: [map()]
  def placement_rules do
    @placement_rules
  end

  @spec leaf_kinds() :: [atom()]
  def leaf_kinds do
    @leaf_kinds ++ @advanced_leaf_kinds
  end

  @spec layout_kinds() :: [atom()]
  def layout_kinds do
    @layout_kinds
  end

  @spec container_kinds() :: [atom()]
  def container_kinds do
    @container_kinds
  end

  @spec valid_default_slot?(atom() | nil, atom() | nil) :: boolean()
  def valid_default_slot?(:fragment, default_slot), do: is_atom(default_slot)
  def valid_default_slot?(_mode, nil), do: true
  def valid_default_slot?(_mode, _default_slot), do: false
end
