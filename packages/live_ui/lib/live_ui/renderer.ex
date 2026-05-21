defmodule LiveUi.Renderer do
  @moduledoc """
  Package-facing entrypoint for canonical `UnifiedIUR` rendering.
  """

  use Phoenix.Component

  alias LiveUi.Style, as: NativeStyle
  alias UnifiedIUR.{Binding, Element, Interaction}

  @component_kinds UnifiedIUR.Widgets.Components.kinds()

  @spec accepts() :: module()
  def accepts, do: Element

  @spec responsibilities() :: [atom()]
  def responsibilities do
    [:consume_canonical_iur, :reuse_native_widgets, :preserve_runtime_continuity]
  end

  @spec supported_kinds() :: [atom()]
  def supported_kinds do
    ([
       :alert_dialog,
       :artifact_row,
       :bar_chart,
       :box,
       :button,
       :canvas,
       :checkbox,
       :cluster_dashboard,
       :column,
       :command_palette,
       :composer_query_preview,
       :collection_picker,
       :confidence_indicator,
       :content,
       :context_selector,
       :context_menu,
       :date_input,
       :diff_banner,
       :dialog,
       :disclosure,
       :field,
       :field_group,
       :file_tree_browser,
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
       :sparkline,
       :spacer,
       :split_pane,
       :status,
       :stream_widget,
       :supervision_tree_viewer,
       :table,
       :thread_card,
       :tabs,
       :text,
       :text_input,
       :time_input,
       :toast,
       :toggle,
       :tree_view,
       :viewport
     ] ++ @component_kinds)
    |> Enum.uniq()
    |> Enum.sort()
  end

  attr(:element, :any, required: true)
  attr(:runtime_state, :any, default: nil)
  attr(:event_target, :any, default: nil)

  def render(%{element: %Element{kind: :top_strip}} = assigns) do
    interaction_attrs = interaction_event_attrs(assigns.element, Map.get(assigns, :event_target))

    assigns =
      assign(assigns, :interaction_attrs, interaction_attrs)
      |> assign(:style_attrs, merge_global_attrs(style_rest(assigns.element), interaction_attrs))

    ~H"""
    <header
      id={element_id(@element, "top-strip")}
      class={["live-ui-top-strip", style_class(@element)]}
      data-live-ui-shell-position="top"
      data-live-ui-theme={get_in(@element.attributes, [:shell, :theme])}
      {@style_attrs}
    >
      <span class="live-ui-top-strip-brand">{get_in(@element.attributes, [:shell, :brand]) || ""}</span>
      <span class="live-ui-top-strip-context">{get_in(@element.attributes, [:shell, :context]) || ""}</span>
      <%= for child <- child_elements(@element, :default) do %>
        <.render element={child} event_target={@event_target} />
      <% end %>
    </header>
    """
  end

  def render(%{element: %Element{kind: :mode_nav}} = assigns) do
    assigns =
      assign(
        assigns,
        :nav_items,
        navigation_items(assigns.element, Map.get(assigns, :event_target))
      )

    ~H"""
    <nav
      id={element_id(@element, "mode-nav")}
      class={["live-ui-mode-nav", style_class(@element)]}
      role="navigation"
      aria-label={get_in(@element.attributes, [:navigation, :aria_label]) || "Mode navigation"}
    >
      <%= for item <- @nav_items do %>
        <button
          class={["live-ui-mode-nav-item", if(Map.get(item, :active), do: "live-ui-mode-nav-item--active")]}
          aria-current={if Map.get(item, :active), do: "page"}
          disabled={Map.get(item, :disabled)}
          {Map.get(item, :attrs, %{})}
        >
          {Map.get(item, :label) || Map.get(item, "label") || ""}
        </button>
      <% end %>
    </nav>
    """
  end

  def render(%{element: %Element{kind: :sidebar_shell}} = assigns) do
    assigns = assign(assigns, :style_attrs, style_rest(assigns.element))

    ~H"""
    <nav
      id={element_id(@element, "sidebar-shell")}
      class={["live-ui-sidebar-shell", style_class(@element)]}
      data-live-ui-shell-position="side"
      data-live-ui-collapsed={get_in(@element.attributes, [:shell, :collapsed?]) || false}
      {@style_attrs}
    >
      <%= for child <- child_elements(@element, :default) do %>
        <.render element={child} event_target={@event_target} />
      <% end %>
    </nav>
    """
  end

  def render(%{element: %Element{kind: :sidebar_section}} = assigns) do
    interaction_attrs = interaction_event_attrs(assigns.element, Map.get(assigns, :event_target))

    assigns =
      assign(assigns, :interaction_attrs, interaction_attrs)
      |> assign(:style_attrs, merge_global_attrs(style_rest(assigns.element), interaction_attrs))

    ~H"""
    <section
      id={element_id(@element, "sidebar-section")}
      class={["live-ui-sidebar-section", style_class(@element)]}
      {@style_attrs}
    >
      <div class="live-ui-sidebar-section-header">
        <h3 class="live-ui-sidebar-section-label">{get_in(@element.attributes, [:section, :label]) || ""}</h3>
        <%= if get_in(@element.attributes, [:section, :action_intent]) do %>
          <button class="live-ui-sidebar-section-action" {@interaction_attrs}>
            {get_in(@element.attributes, [:section, :action_label]) || get_in(@element.attributes, [:section, :action_glyph]) || "+"}
          </button>
        <% end %>
      </div>
      <%= for child <- child_elements(@element, :default) do %>
        <.render element={child} event_target={@event_target} />
      <% end %>
    </section>
    """
  end

  def render(%{element: %Element{kind: :sidebar_item}} = assigns) do
    interaction_attrs = interaction_event_attrs(assigns.element, Map.get(assigns, :event_target))

    assigns =
      assign(assigns, :interaction_attrs, interaction_attrs)
      |> assign(:style_attrs, merge_global_attrs(style_rest(assigns.element), interaction_attrs))

    ~H"""
    <li
      id={element_id(@element, "sidebar-item")}
      class={["live-ui-sidebar-item", if(get_in(@element.attributes, [:item, :selected?]), do: "live-ui-sidebar-item--selected"), style_class(@element)]}
    >
      <button
        class="live-ui-sidebar-item-button"
        aria-current={if get_in(@element.attributes, [:item, :selected?]), do: "page"}
        {@interaction_attrs}
      >
        {get_in(@element.attributes, [:item, :label]) || ""}
        <%= for child <- child_elements(@element, :default) do %>
          <.render element={child} event_target={@event_target} />
        <% end %>
      </button>
    </li>
    """
  end

  def render(%{element: %Element{kind: :unread_badge}} = assigns) do
    count = get_in(assigns.element.attributes, [:status, :count]) || 0
    threshold = get_in(assigns.element.attributes, [:status, :threshold]) || 99

    display =
      cond do
        count <= 0 -> ""
        count > threshold -> "#{threshold}+"
        true -> to_string(count)
      end

    assigns =
      assign(assigns, :count, count)
      |> assign(:display, display)
      |> assign(:style_attrs, style_rest(assigns.element))

    ~H"""
    <span
      id={element_id(@element, "unread-badge")}
      class={["live-ui-unread-badge", style_class(@element)]}
      role="status"
      data-live-ui-unread-count={@count}
      aria-hidden={if @count <= 0, do: "true"}
      {@style_attrs}
    >
      {@display}
    </span>
    """
  end

  # NOTE: `:avatar` is a member of `@content_identity_kinds` (and therefore
  # of `@component_kinds`), so the generic fallback below would shadow any later
  # `:avatar` clause. Keep this specific clause BEFORE the generic
  # `@component_kinds` fallback — mirrors the pattern used by `:command_palette`,
  # `:top_strip`, `:mode_nav`, `:sidebar_shell`, `:sidebar_section`,
  # `:sidebar_item`, and `:unread_badge` above.
  def render(%{element: %Element{kind: :avatar}} = assigns) do
    assigns = assign(assigns, :style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Widgets.Avatar.component
      id={element_id(@element, "avatar")}
      actor_id={string_value(get_in(@element.attributes, [:identity, :actor_id]), element_id(@element, "avatar"))}
      initials={string_optional(get_in(@element.attributes, [:identity, :initials]))}
      image_url={string_optional(get_in(@element.attributes, [:identity, :image_source]))}
      size_variant={avatar_size_variant(get_in(@element.attributes, [:identity, :size]))}
      label_text={string_optional(get_in(@element.attributes, [:accessibility, :label]))}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    />
    """
  end

  # NOTE: `:disclosure` is a member of `@content_identity_kinds` (and therefore
  # of `@component_kinds`), so the generic fallback below would shadow any later
  # `:disclosure` clause. Keep this specific clause BEFORE the generic
  # `@component_kinds` fallback with the other native content-identity clauses.
  def render(%{element: %Element{kind: :disclosure}} = assigns) do
    assigns =
      assigns
      |> assign(
        :open_state,
        get_in(assigns.element.attributes, [:disclosure, :open?]) || false
      )
      |> assign(
        :summary_label,
        string_optional(get_in(assigns.element.attributes, [:disclosure, :summary]))
      )
      |> assign(:style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Widgets.Disclosure.component
      id={element_id(@element, "disclosure")}
      open?={@open_state}
      label={@summary_label}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    >
      <:body :for={child <- child_elements(@element, :default)}>
        <.render element={child} event_target={@event_target} />
      </:body>
    </LiveUi.Widgets.Disclosure.component>
    """
  end

  # NOTE: `:command_palette` is a member of `@layer_callout_kinds` (and therefore
  # of `@component_kinds`), so the generic fallback below would shadow any later
  # `:command_palette` clause. Keep this specific clause BEFORE the generic
  # `@component_kinds` fallback — mirrors the pattern used by `:top_strip`,
  # `:mode_nav`, `:sidebar_shell`, `:sidebar_section`, `:sidebar_item`, and
  # `:unread_badge` above.
  def render(%{element: %Element{kind: :command_palette}} = assigns) do
    assigns =
      assigns
      |> assign(
        :input_attrs,
        direct_change_interaction_attrs(assigns.element, Map.get(assigns, :event_target))
      )
      |> assign(
        :palette_items,
        command_palette_items(assigns.element, Map.get(assigns, :event_target))
      )

    ~H"""
    <LiveUi.Widgets.CommandPalette.component
      id={element_id(@element, "command-palette")}
      query={string_optional(get_in(@element.attributes, [:command_palette, :query]))}
      items={@palette_items}
      input_attrs={@input_attrs}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
    />
    """
  end

  def render(%{element: %Element{kind: :diff_banner}} = assigns) do
    diff = diff_banner_attributes(assigns.element)

    assigns =
      assigns
      |> assign(:diff, diff)
      |> assign(:chips, diff_banner_chips(assigns.element, Map.get(assigns, :event_target)))
      |> assign(:style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Widgets.DiffBanner.component
      id={element_id(@element, "diff-banner")}
      new_count={map_value(@diff, :new_count, 0)}
      changed_count={map_value(@diff, :changed_count, 0)}
      removed_count={map_value(@diff, :removed_count, 0)}
      base_label={map_value(@diff, :base_label)}
      active_filter={map_value(@diff, :active_filter, :all)}
      show_filter_chips?={boolean_default(map_value(@diff, :show_filter_chips?), true)}
      size={map_value(@diff, :size, :default)}
      chips={@chips}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    />
    """
  end

  def render(%{element: %Element{kind: :context_selector}} = assigns) do
    context_selector = context_selector_attributes(assigns.element)

    assigns =
      assigns
      |> assign(:context_selector, context_selector)
      |> assign(
        :groups,
        context_selector_groups(assigns.element, Map.get(assigns, :event_target))
      )
      |> assign(:style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Widgets.ContextSelector.component
      id={element_id(@element, "context-selector")}
      selector_id={string_value(map_value(@context_selector, :selector_id), element_id(@element, "context-selector"))}
      groups={@groups}
      placeholder={string_value(map_value(@context_selector, :placeholder), "Select context...")}
      selected_values={List.wrap(map_value(@context_selector, :selected_values, []))}
      max_selections={map_value(@context_selector, :max_selections, 1)}
      label_prefix={string_value(map_value(@context_selector, :label_prefix), "context:")}
      open?={boolean_default(map_value(@context_selector, :open?), false)}
      disabled?={boolean_default(map_value(@context_selector, :disabled?), false)}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    />
    """
  end

  def render(%{element: %Element{kind: :file_tree_browser}} = assigns) do
    file_tree = file_tree_attributes(assigns.element)

    assigns =
      assigns
      |> assign(:file_tree, file_tree)
      |> assign(:nodes, file_tree_nodes(assigns.element, Map.get(assigns, :event_target)))
      |> assign(:style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Widgets.FileTreeBrowser.component
      id={element_id(@element, "file-tree-browser")}
      tree_id={string_value(map_value(@file_tree, :tree_id), element_id(@element, "file-tree-browser"))}
      root_label={string_value(map_value(@file_tree, :root_label), "Files")}
      nodes={@nodes}
      selected_path={string_optional(map_value(@file_tree, :selected_path))}
      default_expanded?={boolean_default(map_value(@file_tree, :default_expanded?), true)}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    />
    """
  end

  # NOTE: `:presence_dot` is a member of `@content_identity_kinds` (and therefore
  # of `@component_kinds`), so the generic fallback below would shadow any later
  # `:presence_dot` clause. Keep this specific clause BEFORE the generic
  # `@component_kinds` fallback — mirrors the placement pattern established by
  # `:command_palette` above (line 248).
  def render(%{element: %Element{kind: :presence_dot}} = assigns) do
    state = get_in(assigns.element.attributes, [:presence, :state]) || :offline

    aria_label =
      get_in(assigns.element.attributes, [:accessibility, :label]) ||
        get_in(assigns.element.attributes, [:presence, :accessibility_label])

    decorative? =
      get_in(assigns.element.attributes, [:accessibility, :decorative?]) ||
        get_in(assigns.element.attributes, [:presence, :decorative?]) ||
        false

    assigns =
      assigns
      |> assign(:presence_state, state)
      |> assign(:aria_label, aria_label)
      |> assign(:presence_decorative, decorative?)
      |> assign(:style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Widgets.PresenceDot.component
      id={element_id(@element, "presence-dot")}
      aria_label={@aria_label}
      presence_state={@presence_state}
      decorative?={@presence_decorative}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    />
    """
  end

  # NOTE: `:workflow_progress_status_card` is a canonical component kind, so keep this native
  # renderer clause before the generic `@component_kinds` fallback.
  def render(%{element: %Element{kind: :workflow_progress_status_card}} = assigns) do
    assigns = assign(assigns, :style_attrs, style_rest(assigns.element))

    subject = get_in(assigns.element.attributes, [:subject]) || %{}
    status_counts = Map.get(subject, :status_counts, %{})
    dependencies = Map.get(subject, :dependencies, %{})
    activity = Map.get(subject, :activity, %{})
    state = Map.get(subject, :state, %{})
    actions = Map.get(subject, :actions, %{})
    interactions = Map.get(subject, :interactions, %{})
    focus_interaction = Map.get(interactions, :focus)

    assigns =
      assigns
      |> assign(:subject_name, Map.get(subject, :name, ""))
      |> assign(:progress_pct, (Map.get(subject, :progress, 0.0) || 0.0) / 100.0)
      |> assign(:active_count, Map.get(status_counts, :active, 0))
      |> assign(:blocked_count, Map.get(status_counts, :blocked, 0))
      |> assign(:subject_path, Map.get(subject, :path))
      |> assign(:depends_on, dependency_labels(Map.get(dependencies, :depends_on, [])))
      |> assign(:depended_by, dependency_labels(Map.get(dependencies, :depended_by, [])))
      |> assign(:selected?, Map.get(state, :selected?, false))
      |> assign(:focus_intent, interaction_intent(focus_interaction, "focus_subject"))
      |> assign(:last_activity_label, last_activity_label(Map.get(activity, :last_activity_at)))
      |> assign(:open_action, Map.get(actions, :open))

    ~H"""
    <LiveUi.Widgets.WorkflowProgressStatusCard.component
      id={element_id(@element, "workflow-progress-status-card")}
      name={@subject_name}
      progress_pct={@progress_pct}
      active_count={@active_count}
      blocked_count={@blocked_count}
      path={@subject_path}
      last_activity_label={@last_activity_label}
      depends_on={@depends_on}
      depended_by={@depended_by}
      selected?={@selected?}
      focus_intent={@focus_intent}
      open_action={@open_action}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    />
    """
  end

  # NOTE: `:artifact_row` is a member of `@row_artifact_kinds` (and therefore of
  # `@component_kinds`), so the generic fallback below would shadow a later clause.
  # Keep this specific clause BEFORE the generic `@component_kinds` fallback with
  # the other native component-family clauses.
  def render(%{element: %Element{kind: :artifact_row}} = assigns) do
    interaction_attrs = interaction_event_attrs(assigns.element, Map.get(assigns, :event_target))

    assigns =
      assigns
      |> assign(
        :artifact_title,
        string_value(get_in(assigns.element.attributes, [:artifact, :title]), "")
      )
      |> assign(
        :artifact_subtitle,
        string_optional(get_in(assigns.element.attributes, [:artifact, :meta]))
      )
      |> assign(
        :artifact_kind,
        artifact_row_kind(get_in(assigns.element.attributes, [:artifact, :kind]))
      )
      |> assign(
        :artifact_selected,
        boolean_default(get_in(assigns.element.attributes, [:artifact, :active?]), false)
      )
      |> assign(
        :artifact_badges,
        List.wrap(get_in(assigns.element.attributes, [:artifact, :status_badges]))
      )
      |> assign(
        :artifact_counts,
        artifact_row_counts(get_in(assigns.element.attributes, [:artifact, :counts]))
      )
      |> assign(
        :artifact_timestamp,
        get_in(assigns.element.attributes, [:artifact, :timestamp_at])
      )
      |> assign(
        :artifact_active,
        boolean_default(get_in(assigns.element.attributes, [:artifact, :active?]), false)
      )
      |> assign(:style_attrs, merge_global_attrs(style_rest(assigns.element), interaction_attrs))

    ~H"""
    <LiveUi.Widgets.ArtifactRow.component
      id={element_id(@element, "artifact-row")}
      title={@artifact_title}
      subtitle={@artifact_subtitle}
      kind={@artifact_kind}
      selected?={@artifact_selected}
      status_badges={@artifact_badges}
      counts={@artifact_counts}
      timestamp_at={@artifact_timestamp}
      active?={@artifact_active}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    >
      <:actions :for={child <- child_elements(@element, :default)}>
        <.render element={child} event_target={@event_target} />
      </:actions>
    </LiveUi.Widgets.ArtifactRow.component>
    """
  end

  # NOTE: `:thread_card` is a member of `@row_artifact_kinds` and therefore of
  # `@component_kinds`; keep this native clause before the generic component
  # fallback so the canonical artifact renders through the dedicated boundary.
  def render(%{element: %Element{kind: :thread_card}} = assigns) do
    thread = get_in(assigns.element.attributes, [:thread]) || %{}

    assigns =
      assigns
      |> assign(:thread, thread)
      |> assign(
        :open_attrs,
        interaction_event_attrs(assigns.element, Map.get(assigns, :event_target))
      )
      |> assign(:style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Widgets.ThreadCard.component
      id={element_id(@element, "thread-card")}
      thread_id={string_value(map_value(@thread, :thread_id), "")}
      title={string_value(map_value(@thread, :title), "")}
      reply_count={integer_value(map_value(@thread, :reply_count), 0)}
      seed_quote={string_value(map_value(@thread, :seed_quote), "")}
      participants={get_in(@element.attributes, [:participants]) || []}
      progress_pct={map_value(@thread, :progress_pct)}
      last_activity_at={map_value(@thread, :last_activity_at)}
      open_attrs={@open_attrs}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    />
    """
  end

  # NOTE: `:segmented_button_group` is a member of `@component_kinds` through the
  # `:form_control_and_composer` family, so the generic fallback below would
  # shadow any later `:segmented_button_group` clause. Keep this specific clause
  # BEFORE the generic `@component_kinds` fallback with the other native
  # component-family clauses.
  def render(%{element: %Element{kind: :segmented_button_group}} = assigns) do
    assigns =
      assigns
      |> assign(
        :options,
        segmented_button_group_options(assigns.element, Map.get(assigns, :event_target))
      )
      |> assign(:selected_value, selection_active_value(assigns.element))
      |> assign(:label, segmented_button_group_label(assigns.element))
      |> assign(:style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Widgets.SegmentedButtonGroup.component
      id={element_id(@element, "segmented-button-group")}
      options={@options}
      selected_value={@selected_value}
      label={@label}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    />
    """
  end

  # NOTE: `:collection_picker` is a canonical form-control component. Keep the
  # native renderer clause before the generic component fallback so the search,
  # selection, and command controls receive canonical interaction transport.
  def render(%{element: %Element{kind: :collection_picker}} = assigns) do
    picker = collection_picker_attributes(assigns.element)
    event_target = Map.get(assigns, :event_target)

    assigns =
      assigns
      |> assign(:picker, picker)
      |> assign(:filters, collection_picker_filters(picker))
      |> assign(:items, collection_picker_items(picker))
      |> assign(:suggestions, collection_picker_suggestions(picker))
      |> assign(:query_attrs, collection_picker_query_attrs(assigns.element, event_target))
      |> assign(
        :filter_attrs,
        collection_picker_filter_attrs(assigns.element, event_target, picker)
      )
      |> assign(:item_attrs, collection_picker_item_attrs(assigns.element, event_target, picker))
      |> assign(
        :suggestion_accept_attrs,
        collection_picker_suggestion_attrs(
          assigns.element,
          event_target,
          picker,
          :accept_suggestion
        )
      )
      |> assign(
        :suggestion_dismiss_attrs,
        collection_picker_suggestion_attrs(
          assigns.element,
          event_target,
          picker,
          :dismiss_suggestion
        )
      )
      |> assign(:style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Widgets.CollectionPicker.component
      id={element_id(@element, "collection-picker")}
      picker_id={string_value(map_value(@picker, :picker_id), element_id(@element, "collection-picker"))}
      title={string_optional(map_value(@picker, :title))}
      query={string_value(map_value(@picker, :query), "")}
      placeholder={string_value(map_value(@picker, :placeholder), "Search collection")}
      filters={@filters}
      items={@items}
      suggestions={@suggestions}
      empty_label={string_value(map_value(@picker, :empty_label), "No matching items.")}
      loading?={boolean_default(map_value(@picker, :loading?), false)}
      density={map_value(@picker, :density)}
      query_attrs={@query_attrs}
      filter_attrs={@filter_attrs}
      item_attrs={@item_attrs}
      suggestion_accept_attrs={@suggestion_accept_attrs}
      suggestion_dismiss_attrs={@suggestion_dismiss_attrs}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    />
    """
  end

  # NOTE: `:list_repeat` is a member of `@composition_behavior_kinds` (and therefore
  # of `@component_kinds`), so the generic fallback below would shadow any later
  # `:list_repeat` clause. Keep this specific clause BEFORE the generic
  # `@component_kinds` fallback with the other native component-family clauses.
  #
  # Hydration: the IUR hydration pass runs before rendering and produces
  # pre-hydrated child Element.t() children. The renderer extracts those children
  # and passes them to the Stage-4 component as the `items` list.
  def render(%{element: %Element{kind: :list_repeat}} = assigns) do
    repeat_binding =
      assigns.element
      |> get_in([Access.key(:attributes), :repeat, :binding_id])
      |> case do
        nil -> nil
        value -> to_string(value)
      end

    hydrated_children = child_elements(assigns.element, :default)

    assigns =
      assigns
      |> assign(:repeat_binding, repeat_binding)
      |> assign(:items, hydrated_children)
      |> assign(:style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Widgets.ListRepeat.component
      id={element_id(@element, "list-repeat")}
      items={@items}
      repeat_binding={@repeat_binding}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    >
      <:row :let={child}>
        <.render element={child} event_target={@event_target} />
      </:row>
    </LiveUi.Widgets.ListRepeat.component>
    """
  end

  # NOTE: `:right_rail` is a canonical component kind, so keep this native
  # renderer clause before the generic `@component_kinds` fallback.
  def render(%{element: %Element{kind: :right_rail}} = assigns) do
    rail = rail_attributes(assigns.element)
    panels = right_rail_panels(rail)

    assigns =
      assigns
      |> assign(:rail, rail)
      |> assign(:panels, panels)
      |> assign(:active_panel, right_rail_active_panel(rail, panels))
      |> assign(
        :panel_attrs,
        right_rail_panel_attrs(assigns.element, Map.get(assigns, :event_target), panels)
      )
      |> assign(
        :collapse_attrs,
        right_rail_collapse_attrs(assigns.element, Map.get(assigns, :event_target))
      )
      |> assign(:style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Widgets.RightRail.component
      id={element_id(@element, "right-rail")}
      side={map_value(@rail, :side, :right)}
      panels={@panels}
      active_panel={@active_panel}
      collapsed?={boolean_default(map_value(@rail, :collapsed?), false)}
      collapsible?={boolean_default(map_value(@rail, :collapsible?), true)}
      density={map_value(@rail, :density)}
      width={map_value(@rail, :width)}
      panel_attrs={@panel_attrs}
      collapse_attrs={@collapse_attrs}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    >
      <:panel :for={panel <- @panels} id={rail_panel_id(panel)}>
        <%= for child <- rail_panel_children(@element, panel) do %>
          <.render element={child} event_target={@event_target} />
        <% end %>
      </:panel>
    </LiveUi.Widgets.RightRail.component>
    """
  end

  # NOTE: `:composer_query_preview` is a canonical layer-shell component. Keep
  # this native renderer clause before the generic component fallback so action
  # buttons receive canonical interaction transport.
  def render(%{element: %Element{kind: :composer_query_preview}} = assigns) do
    preview = query_preview_attributes(assigns.element)

    assigns =
      assigns
      |> assign(:preview, preview)
      |> assign(
        :action_attrs,
        query_preview_action_attrs(assigns.element, Map.get(assigns, :event_target), preview)
      )
      |> assign(:style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Widgets.ComposerQueryPreview.component
      id={element_id(@element, "composer-query-preview")}
      composer_id={string_value(map_value(@preview, :composer_id), "")}
      query={string_value(map_value(@preview, :query), "")}
      preview_state={map_value(@preview, :preview_state, :empty)}
      explanation={string_optional(map_value(@preview, :explanation))}
      metrics={map_value(@preview, :metrics)}
      findings={List.wrap(map_value(@preview, :findings, []))}
      max_findings_shown={integer_value(map_value(@preview, :max_findings_shown), 2)}
      error_message={string_optional(map_value(@preview, :error_message))}
      loading_label={string_value(map_value(@preview, :loading_label), "Searching")}
      empty_label={string_value(map_value(@preview, :empty_label), "No results for this query.")}
      open_label={string_value(map_value(@preview, :open_label), "Open query")}
      save_label={string_value(map_value(@preview, :save_label), "Save query")}
      dismiss_attrs={Map.get(@action_attrs, :dismiss, %{})}
      open_attrs={Map.get(@action_attrs, :open, %{})}
      save_attrs={Map.get(@action_attrs, :save, %{})}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    />
    """
  end

  def render(%{element: %Element{kind: kind}} = assigns) when kind in @component_kinds do
    assigns = assign(assigns, :style_attrs, style_rest(assigns.element))

    ~H"""
    <section
      id={element_id(@element, "component")}
      class={["live-ui-canonical-component", "live-ui-canonical-component-#{@element.kind}", style_class(@element)]}
      data-live-ui-component-kind={@element.kind}
      data-live-ui-component-family={get_in(@element.attributes, [:component, :family])}
      data-live-ui-unsupported-native-component="fallback"
      {@style_attrs}
    >
      <%= for child <- child_elements(@element, :default) do %>
        <.render element={child} event_target={@event_target} />
      <% end %>
    </section>
    """
  end

  def render(%{element: %Element{kind: :text}} = assigns) do
    assigns = assign(assigns, :style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Widgets.Text.component
      id={element_id(@element, "text")}
      content={content_text(@element)}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    />
    """
  end

  def render(%{element: %Element{kind: :label}} = assigns) do
    ~H"""
    <LiveUi.Widgets.Label.component
      id={element_id(@element, "label")}
      for={label_for(@element)}
      content={content_text(@element)}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
    />
    """
  end

  def render(%{element: %Element{kind: :icon}} = assigns) do
    ~H"""
    <LiveUi.Widgets.Icon.component
      id={element_id(@element, "icon")}
      name={string_value(get_in(@element.attributes, [:icon, :name]), "icon")}
      set={string_optional(get_in(@element.attributes, [:icon, :set]))}
      fallback_text={string_optional(get_in(@element.attributes, [:icon, :fallback_text]))}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
    />
    """
  end

  def render(%{element: %Element{kind: :image}} = assigns) do
    ~H"""
    <LiveUi.Widgets.Image.component
      id={element_id(@element, "image")}
      src={string_value(get_in(@element.attributes, [:image, :source]), "")}
      alt={string_value(get_in(@element.attributes, [:image, :alt_text]), "")}
      fit={string_optional(get_in(@element.attributes, [:image, :fit]))}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
    />
    """
  end

  def render(%{element: %Element{kind: :button}} = assigns) do
    interaction_attrs = interaction_event_attrs(assigns.element, Map.get(assigns, :event_target))

    assigns =
      assign(assigns, :interaction_attrs, interaction_attrs)
      |> assign(
        :style_attrs,
        merge_global_attrs(style_rest(assigns.element), interaction_attrs)
      )

    ~H"""
    <LiveUi.Widgets.Button.component
      id={element_id(@element, "button")}
      label={content_text(@element)}
      disabled={state_boolean(@element, :disabled?)}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    />
    """
  end

  def render(%{element: %Element{kind: :link}} = assigns) do
    assigns =
      assign(
        assigns,
        :interaction_attrs,
        interaction_event_attrs(assigns.element, Map.get(assigns, :event_target))
      )

    ~H"""
    <LiveUi.Widgets.Link.component
      id={element_id(@element, "link")}
      label={content_text(@element)}
      href={string_value(get_in(@element.attributes, [:link, :target]), "#")}
      external={state_boolean(@element, [:link, :external?])}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@interaction_attrs}
    />
    """
  end

  def render(%{element: %Element{kind: :separator}} = assigns) do
    ~H"""
    <LiveUi.Widgets.Separator.component
      id={element_id(@element, "separator")}
      orientation={string_value(get_in(@element.attributes, [:separator, :orientation]), "horizontal")}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
    />
    """
  end

  def render(%{element: %Element{kind: :spacer}} = assigns) do
    ~H"""
    <LiveUi.Widgets.Spacer.component
      id={element_id(@element, "spacer")}
      size={string_value(get_in(@element.attributes, [:spacer, :size]), "md")}
      grow={integer_value(get_in(@element.attributes, [:spacer, :grow]), 0)}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
    />
    """
  end

  def render(%{element: %Element{kind: :content}} = assigns) do
    ~H"""
    <LiveUi.Widgets.Content.component
      id={element_id(@element, "content")}
      role={string_value(get_in(@element.attributes, [:container, :role]), "content")}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
    >
      <%= for child <- child_elements(@element) do %>
        <.render element={child} event_target={@event_target} />
      <% end %>
    </LiveUi.Widgets.Content.component>
    """
  end

  def render(%{element: %Element{kind: :box}} = assigns) do
    accessibility_attrs = accessibility_attrs(assigns.element)

    assigns =
      assign(assigns, :accessibility_attrs, accessibility_attrs)
      |> assign(
        :style_attrs,
        merge_global_attrs(style_rest(assigns.element), accessibility_attrs)
      )

    ~H"""
    <LiveUi.Widgets.Box.component
      id={element_id(@element, "box")}
      padding={string_optional(get_in(@element.attributes, [:container, :padding]))}
      border={string_optional(get_in(@element.attributes, [:container, :border]))}
      background={string_optional(get_in(@element.attributes, [:container, :background]))}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    >
      <%= for child <- child_elements(@element) do %>
        <.render element={child} event_target={@event_target} />
      <% end %>
    </LiveUi.Widgets.Box.component>
    """
  end

  def render(%{element: %Element{kind: :row}} = assigns) do
    assigns = assign(assigns, :style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Layout.Row.component
      id={element_id(@element, "row")}
      gap={string_optional(get_in(@element.attributes, [:layout, :gap]))}
      padding={string_optional(get_in(@element.attributes, [:layout, :padding]))}
      align={string_optional(get_in(@element.attributes, [:layout, :align]))}
      justify={string_optional(get_in(@element.attributes, [:layout, :justify]))}
      width={string_optional(get_in(@element.attributes, [:layout, :width]))}
      height={string_optional(get_in(@element.attributes, [:layout, :height]))}
      min_width={string_optional(get_in(@element.attributes, [:layout, :min_width]))}
      min_height={string_optional(get_in(@element.attributes, [:layout, :min_height]))}
      max_width={string_optional(get_in(@element.attributes, [:layout, :max_width]))}
      max_height={string_optional(get_in(@element.attributes, [:layout, :max_height]))}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    >
      <%= for child <- child_elements(@element) do %>
        <.render element={child} event_target={@event_target} />
      <% end %>
    </LiveUi.Layout.Row.component>
    """
  end

  def render(%{element: %Element{kind: :column}} = assigns) do
    assigns = assign(assigns, :style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Layout.Column.component
      id={element_id(@element, "column")}
      gap={string_optional(get_in(@element.attributes, [:layout, :gap]))}
      padding={string_optional(get_in(@element.attributes, [:layout, :padding]))}
      align={string_optional(get_in(@element.attributes, [:layout, :align]))}
      justify={string_optional(get_in(@element.attributes, [:layout, :justify]))}
      width={string_optional(get_in(@element.attributes, [:layout, :width]))}
      height={string_optional(get_in(@element.attributes, [:layout, :height]))}
      min_width={string_optional(get_in(@element.attributes, [:layout, :min_width]))}
      min_height={string_optional(get_in(@element.attributes, [:layout, :min_height]))}
      max_width={string_optional(get_in(@element.attributes, [:layout, :max_width]))}
      max_height={string_optional(get_in(@element.attributes, [:layout, :max_height]))}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    >
      <%= for child <- child_elements(@element) do %>
        <.render element={child} event_target={@event_target} />
      <% end %>
    </LiveUi.Layout.Column.component>
    """
  end

  def render(%{element: %Element{kind: :grid}} = assigns) do
    assigns = assign(assigns, :style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Layout.Grid.component
      id={element_id(@element, "grid")}
      columns={integer_optional(get_in(@element.attributes, [:layout, :columns]))}
      rows={integer_optional(get_in(@element.attributes, [:layout, :rows]))}
      gap={string_optional(get_in(@element.attributes, [:layout, :gap]))}
      padding={string_optional(get_in(@element.attributes, [:layout, :padding]))}
      align={string_optional(get_in(@element.attributes, [:layout, :align]))}
      justify={string_optional(get_in(@element.attributes, [:layout, :justify]))}
      width={string_optional(get_in(@element.attributes, [:layout, :width]))}
      height={string_optional(get_in(@element.attributes, [:layout, :height]))}
      min_width={string_optional(get_in(@element.attributes, [:layout, :min_width]))}
      min_height={string_optional(get_in(@element.attributes, [:layout, :min_height]))}
      max_width={string_optional(get_in(@element.attributes, [:layout, :max_width]))}
      max_height={string_optional(get_in(@element.attributes, [:layout, :max_height]))}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    >
      <%= for child <- child_elements(@element) do %>
        <.render element={child} event_target={@event_target} />
      <% end %>
    </LiveUi.Layout.Grid.component>
    """
  end

  def render(%{element: %Element{kind: :form_builder}} = assigns) do
    assigns =
      assign(
        assigns,
        :form_interaction_attrs,
        form_interaction_attrs(assigns.element, Map.get(assigns, :event_target))
      )

    ~H"""
    <LiveUi.Forms.FormBuilder.component
      id={element_id(@element, "form-builder")}
      autocomplete={boolean_default(get_in(@element.attributes, [:form, :autocomplete?]), true)}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@form_interaction_attrs}
    >
      <%= for child <- child_elements(@element) do %>
        <.render element={child} event_target={@event_target} />
      <% end %>
    </LiveUi.Forms.FormBuilder.component>
    """
  end

  def render(%{element: %Element{kind: :field_group}} = assigns) do
    ~H"""
    <LiveUi.Forms.FieldGroup.component
      id={element_id(@element, "field-group")}
      legend={string_optional(get_in(@element.attributes, [:group, :legend]))}
      description={string_optional(get_in(@element.attributes, [:group, :description]))}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
    >
      <%= for child <- child_elements(@element) do %>
        <.render element={child} event_target={@event_target} />
      <% end %>
    </LiveUi.Forms.FieldGroup.component>
    """
  end

  def render(%{element: %Element{kind: :field}} = assigns) do
    ~H"""
    <LiveUi.Forms.Field.component
      id={element_id(@element, "field")}
      name={string_optional(get_in(@element.attributes, [:field, :name]))}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
    >
      <:label :for={child <- child_elements(@element, :label)}>
        <.render element={child} event_target={@event_target} />
      </:label>
      <:control :for={child <- child_elements(@element, :control)}>
        <.render element={child} event_target={@event_target} />
      </:control>
      <:help :for={child <- child_elements(@element, :help)}>
        <.render element={child} event_target={@event_target} />
      </:help>
    </LiveUi.Forms.Field.component>
    """
  end

  def render(%{element: %Element{kind: kind}} = assigns)
      when kind in [:text_input, :numeric_input, :date_input, :time_input, :file_input] do
    assigns =
      assign(assigns, :change_interaction, primary_change_interaction(assigns.element))
      |> assign(:style_attrs, style_rest(assigns.element))

    ~H"""
    <%= if @change_interaction && @event_target do %>
      <form
        id={interaction_form_id(@element, "input")}
        data-live-ui-interaction-form="true"
        phx-input="canonical_interaction"
        phx-change="canonical_interaction"
        phx-target={@event_target}
      >
        <input type="hidden" name="interaction" value={encode_interaction(@change_interaction)} />
        <input type="hidden" name="element_id" value={element_id(@element, "element")} />
        <input type="hidden" name="widget" value={to_string(@element.kind)} />
        <LiveUi.Widgets.TextInput.component
          id={element_id(@element, "input")}
          name={binding_name(@element)}
          value={binding_value(@element)}
          placeholder={string_optional(get_in(@element.attributes, [:input, :placeholder]))}
          input_type={input_type(@element.kind)}
          tone={style_tone(@element)}
          variant={theme_variant(@element)}
          state={style_state(@element)}
          class={style_class(@element)}
          {@style_attrs}
        />
      </form>
    <% else %>
      <LiveUi.Widgets.TextInput.component
        id={element_id(@element, "input")}
        name={binding_name(@element)}
        value={binding_value(@element)}
        placeholder={string_optional(get_in(@element.attributes, [:input, :placeholder]))}
        input_type={input_type(@element.kind)}
        tone={style_tone(@element)}
        variant={theme_variant(@element)}
        state={style_state(@element)}
        class={style_class(@element)}
        {@style_attrs}
      />
    <% end %>
    """
  end

  def render(%{element: %Element{kind: kind}} = assigns)
      when kind in [:toggle, :checkbox] do
    assigns =
      assign(assigns, :change_interaction, primary_control_interaction(assigns.element))

    ~H"""
    <%= if @change_interaction && @event_target do %>
      <form
        id={interaction_form_id(@element, "toggle")}
        data-live-ui-interaction-form="true"
        phx-change="canonical_interaction"
        phx-target={@event_target}
      >
        <input type="hidden" name="interaction" value={encode_interaction(@change_interaction)} />
        <input type="hidden" name="element_id" value={element_id(@element, "element")} />
        <input type="hidden" name="widget" value={to_string(@element.kind)} />
        <LiveUi.Widgets.Toggle.component
          id={element_id(@element, "toggle")}
          name={binding_name(@element)}
          checked={boolean_default(binding_value(@element), false)}
          tone={style_tone(@element)}
          variant={theme_variant(@element)}
          state={style_state(@element)}
          class={style_class(@element)}
        />
      </form>
    <% else %>
      <LiveUi.Widgets.Toggle.component
        id={element_id(@element, "toggle")}
        name={binding_name(@element)}
        checked={boolean_default(binding_value(@element), false)}
        tone={style_tone(@element)}
        variant={theme_variant(@element)}
        state={style_state(@element)}
        class={style_class(@element)}
      />
    <% end %>
    """
  end

  def render(%{element: %Element{kind: kind}} = assigns)
      when kind in [:select, :pick_list, :radio_group] do
    assigns =
      assign(assigns, :change_interaction, primary_control_interaction(assigns.element))

    ~H"""
    <%= if @change_interaction && @event_target do %>
      <form
        id={interaction_form_id(@element, "select")}
        data-live-ui-interaction-form="true"
        phx-change="canonical_interaction"
        phx-target={@event_target}
      >
        <input type="hidden" name="interaction" value={encode_interaction(@change_interaction)} />
        <input type="hidden" name="element_id" value={element_id(@element, "element")} />
        <input type="hidden" name="widget" value={to_string(@element.kind)} />
        <LiveUi.Widgets.Select.component
          id={element_id(@element, "select")}
          name={binding_name(@element)}
          options={selection_options(@element)}
          multiple={selection_multiple?(@element, @element.kind)}
          tone={style_tone(@element)}
          variant={theme_variant(@element)}
          state={style_state(@element)}
          class={style_class(@element)}
        />
      </form>
    <% else %>
      <LiveUi.Widgets.Select.component
        id={element_id(@element, "select")}
        name={binding_name(@element)}
        options={selection_options(@element)}
        multiple={selection_multiple?(@element, @element.kind)}
        tone={style_tone(@element)}
        variant={theme_variant(@element)}
        state={style_state(@element)}
        class={style_class(@element)}
      />
    <% end %>
    """
  end

  def render(%{element: %Element{kind: :menu}} = assigns) do
    ~H"""
    <LiveUi.Widgets.Menu.component
      id={element_id(@element, "menu")}
      items={navigation_items(@element, @event_target)}
      active_item={string_optional(get_in(@element.attributes, [:navigation, :active_item]))}
      orientation={string_value(get_in(@element.attributes, [:navigation, :orientation]), "vertical")}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
    />
    """
  end

  def render(%{element: %Element{kind: :tabs}} = assigns) do
    assigns = assign(assigns, :style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Widgets.Tabs.component
      id={element_id(@element, "tabs")}
      items={navigation_items(@element, @event_target)}
      active_item={string_optional(get_in(@element.attributes, [:navigation, :active_item]))}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    />
    """
  end

  def render(%{element: %Element{kind: :list}} = assigns) do
    assigns = assign(assigns, :style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Widgets.List.component
      id={element_id(@element, "list")}
      items={list_items(@element, @event_target)}
      ordered={boolean_default(get_in(@element.attributes, [:list, :ordered?]), false)}
      selection_mode={string_value(get_in(@element.attributes, [:list, :selection_mode]), "single")}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    />
    """
  end

  def render(%{element: %Element{kind: :table}} = assigns) do
    ~H"""
    <LiveUi.Widgets.Table.component
      id={element_id(@element, "table")}
      columns={get_in(@element.attributes, [:table, :columns]) || []}
      rows={table_rows(@element, @event_target)}
      dense={boolean_default(get_in(@element.attributes, [:table, :dense?]), false)}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
    />
    """
  end

  def render(%{element: %Element{kind: :tree_view}} = assigns) do
    assigns = assign(assigns, :style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Widgets.TreeView.component
      id={element_id(@element, "tree-view")}
      nodes={tree_nodes(@element, @event_target)}
      selection_mode={string_value(get_in(@element.attributes, [:tree, :selection_mode]), "single")}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    />
    """
  end

  def render(%{element: %Element{kind: :status}} = assigns) do
    assigns = assign(assigns, :style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Widgets.Status.component
      id={element_id(@element, "status")}
      text={string_value(get_in(@element.attributes, [:feedback, :text]), "")}
      severity={string_value(get_in(@element.attributes, [:feedback, :severity]), "info")}
      status={string_value(get_in(@element.attributes, [:feedback, :status]), "idle")}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    />
    """
  end

  def render(%{element: %Element{kind: :progress}} = assigns) do
    ~H"""
    <LiveUi.Widgets.Progress.component
      id={element_id(@element, "progress")}
      current={integer_value(get_in(@element.attributes, [:progress, :current]), 0)}
      total={integer_value(get_in(@element.attributes, [:progress, :total]), 100)}
      indeterminate={boolean_default(get_in(@element.attributes, [:progress, :indeterminate?]), false)}
      label={string_optional(get_in(@element.attributes, [:progress, :label]))}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
    />
    """
  end

  def render(%{element: %Element{kind: :gauge}} = assigns) do
    ~H"""
    <LiveUi.Widgets.Gauge.component
      id={element_id(@element, "gauge")}
      value={integer_value(get_in(@element.attributes, [:gauge, :value]), 0)}
      min={integer_value(get_in(@element.attributes, [:gauge, :min]), 0)}
      max={integer_value(get_in(@element.attributes, [:gauge, :max]), 100)}
      label={string_optional(get_in(@element.attributes, [:gauge, :label]))}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
    />
    """
  end

  def render(%{element: %Element{kind: :inline_feedback}} = assigns) do
    assigns = assign(assigns, :style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Widgets.InlineFeedback.component
      id={element_id(@element, "inline-feedback")}
      message={string_value(get_in(@element.attributes, [:feedback, :message]), "")}
      title={string_optional(get_in(@element.attributes, [:feedback, :title]))}
      severity={string_value(get_in(@element.attributes, [:feedback, :severity]), "info")}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    />
    """
  end

  def render(%{element: %Element{kind: :confidence_indicator}} = assigns) do
    thresholds = get_in(assigns.element.attributes, [:confidence, :thresholds]) || %{}

    assigns =
      assigns
      |> assign(:style_attrs, style_rest(assigns.element))
      |> assign(
        :value,
        float_value(get_in(assigns.element.attributes, [:confidence, :value]), 0.0)
      )
      |> assign(
        :warn_threshold,
        float_value(Map.get(thresholds, :warn, Map.get(thresholds, "warn")), 0.5)
      )
      |> assign(
        :pass_threshold,
        float_value(Map.get(thresholds, :pass, Map.get(thresholds, "pass")), 0.8)
      )
      |> assign(
        :label,
        string_optional(get_in(assigns.element.attributes, [:confidence, :label]))
      )
      |> assign(
        :show_numeric?,
        boolean_default(get_in(assigns.element.attributes, [:confidence, :show_numeric?]), true)
      )
      |> assign(
        :show_glyph?,
        boolean_default(get_in(assigns.element.attributes, [:confidence, :show_glyph?]), true)
      )
      |> assign(
        :size,
        string_value(get_in(assigns.element.attributes, [:confidence, :size]), "medium")
      )

    ~H"""
    <LiveUi.Widgets.ConfidenceIndicator.component
      id={element_id(@element, "confidence-indicator")}
      value={@value}
      warn_threshold={@warn_threshold}
      pass_threshold={@pass_threshold}
      label={@label}
      show_numeric?={@show_numeric?}
      show_glyph?={@show_glyph?}
      size={@size}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    />
    """
  end

  def render(%{element: %Element{kind: :markdown_viewer}} = assigns) do
    assigns = assign(assigns, :style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Widgets.MarkdownViewer.component
      id={element_id(@element, "markdown-viewer")}
      source={string_value(get_in(@element.attributes, [:document, :source]), "")}
      mode={string_value(get_in(@element.attributes, [:document, :mode]), "rendered")}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    />
    """
  end

  def render(%{element: %Element{kind: :log_viewer}} = assigns) do
    ~H"""
    <LiveUi.Widgets.LogViewer.component
      id={element_id(@element, "log-viewer")}
      entries={get_in(@element.attributes, [:logs, :entries]) || []}
      wrap={boolean_default(get_in(@element.attributes, [:logs, :wrap?]), true)}
      show_timestamps={boolean_default(get_in(@element.attributes, [:logs, :show_timestamps?]), true)}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
    />
    """
  end

  def render(%{element: %Element{kind: :stream_widget}} = assigns) do
    assigns = assign(assigns, :style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Widgets.StreamWidget.component
      id={element_id(@element, "stream-widget")}
      entries={get_in(@element.attributes, [:stream, :entries]) || []}
      ordering={string_value(get_in(@element.attributes, [:stream, :ordering]), "append_only")}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    />
    """
  end

  def render(%{element: %Element{kind: :process_monitor}} = assigns) do
    ~H"""
    <LiveUi.Widgets.ProcessMonitor.component
      id={element_id(@element, "process-monitor")}
      processes={get_in(@element.attributes, [:monitor, :processes]) || []}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
    />
    """
  end

  def render(%{element: %Element{kind: :cluster_dashboard}} = assigns) do
    assigns = assign(assigns, :style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Widgets.ClusterDashboard.component
      id={element_id(@element, "cluster-dashboard")}
      nodes={get_in(@element.attributes, [:cluster, :nodes]) || []}
      summary={get_in(@element.attributes, [:cluster, :summary]) || %{}}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    />
    """
  end

  def render(%{element: %Element{kind: :supervision_tree_viewer}} = assigns) do
    ~H"""
    <LiveUi.Widgets.SupervisionTreeViewer.component
      id={element_id(@element, "supervision-tree-viewer")}
      nodes={get_in(@element.attributes, [:inspection, :nodes]) || []}
      expanded={boolean_default(get_in(@element.attributes, [:inspection, :expanded?]), true)}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
    />
    """
  end

  def render(%{element: %Element{kind: :sparkline}} = assigns) do
    ~H"""
    <LiveUi.Widgets.Sparkline.component
      id={element_id(@element, "sparkline")}
      series={chart_values(@element)}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
    />
    """
  end

  def render(%{element: %Element{kind: :bar_chart}} = assigns) do
    assigns = assign(assigns, :style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Widgets.BarChart.component
      id={element_id(@element, "bar-chart")}
      series={get_in(@element.attributes, [:chart, :series]) || []}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    />
    """
  end

  def render(%{element: %Element{kind: :line_chart}} = assigns) do
    assigns = assign(assigns, :style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Widgets.LineChart.component
      id={element_id(@element, "line-chart")}
      series={get_in(@element.attributes, [:chart, :series]) || []}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    />
    """
  end

  def render(%{element: %Element{kind: :dialog}} = assigns) do
    assigns = assign(assigns, :style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Widgets.Dialog.component
      id={element_id(@element, "dialog")}
      title={string_optional(get_in(@element.attributes, [:dialog, :title]))}
      modal={boolean_default(get_in(@element.attributes, [:dialog, :modal?]), true)}
      dismissible={boolean_default(get_in(@element.attributes, [:dialog, :dismissible?]), true)}
      size={string_value(get_in(@element.attributes, [:dialog, :size]), "md")}
      background_fill={string_value(get_in(@element.attributes, [:dialog, :background_fill]), "scrim")}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    >
      <%= for child <- child_elements(@element, :content) do %>
        <.render element={child} event_target={@event_target} />
      <% end %>
    </LiveUi.Widgets.Dialog.component>
    """
  end

  def render(%{element: %Element{kind: :alert_dialog}} = assigns) do
    assigns = assign(assigns, :style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Widgets.AlertDialog.component
      id={element_id(@element, "alert-dialog")}
      title={string_optional(get_in(@element.attributes, [:alert_dialog, :title]))}
      severity={string_value(get_in(@element.attributes, [:alert_dialog, :severity]), "warning")}
      requires_confirmation={boolean_default(get_in(@element.attributes, [:alert_dialog, :requires_confirmation?]), true)}
      background_fill={string_value(get_in(@element.attributes, [:alert_dialog, :background_fill]), "scrim")}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    >
      <%= for child <- child_elements(@element, :content) do %>
        <.render element={child} event_target={@event_target} />
      <% end %>
    </LiveUi.Widgets.AlertDialog.component>
    """
  end

  def render(%{element: %Element{kind: :toast}} = assigns) do
    assigns = assign(assigns, :style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Widgets.Toast.component
      id={element_id(@element, "toast")}
      placement={placement_value(get_in(@element.attributes, [:toast, :placement]), "top-end")}
      duration_ms={integer_value(get_in(@element.attributes, [:toast, :duration_ms]), 5000)}
      severity={string_value(get_in(@element.attributes, [:toast, :severity]), "info")}
      transient={boolean_default(get_in(@element.attributes, [:toast, :transient?]), true)}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    >
      <%= for child <- child_elements(@element, :content) do %>
        <.render element={child} event_target={@event_target} />
      <% end %>
    </LiveUi.Widgets.Toast.component>
    """
  end

  def render(%{element: %Element{kind: :context_menu}} = assigns) do
    ~H"""
    <LiveUi.Widgets.ContextMenu.component
      id={element_id(@element, "context-menu")}
      items={context_menu_items(@element, @event_target)}
      placement={placement_value(get_in(@element.attributes, [:context_menu, :placement]), "bottom-start")}
      anchor={get_in(@element.attributes, [:context_menu, :anchor]) || %{}}
      active_item={string_optional(get_in(@element.attributes, [:context_menu, :active_item]))}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
    />
    """
  end

  def render(%{element: %Element{kind: :overlay}} = assigns) do
    assigns = assign(assigns, :style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Widgets.OverlaySurface.component
      id={element_id(@element, "overlay-surface")}
      mode={string_value(get_in(@element.attributes, [:overlay, :mode]), "stacked")}
      background_fill={string_value(get_in(@element.attributes, [:overlay, :background_fill]), "transparent")}
      dismissible={boolean_default(get_in(@element.attributes, [:overlay, :dismissible?]), false)}
      focus_scope={string_optional(get_in(@element.attributes, [:overlay, :focus_scope]))}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    >
      <:base :for={child <- child_elements(@element, :base)}>
        <.render element={child} event_target={@event_target} />
      </:base>
      <:overlay :for={child <- overlay_children(@element)}>
        <.render element={child} event_target={@event_target} />
      </:overlay>
    </LiveUi.Widgets.OverlaySurface.component>
    """
  end

  def render(%{element: %Element{kind: :viewport}} = assigns) do
    assigns = assign(assigns, :style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Widgets.Viewport.component
      id={element_id(@element, "viewport")}
      axis={string_value(get_in(@element.attributes, [:viewport, :axis]), "vertical")}
      offset_x={integer_value(get_in(@element.attributes, [:viewport, :offset, :x]), 0)}
      offset_y={integer_value(get_in(@element.attributes, [:viewport, :offset, :y]), 0)}
      clip={boolean_default(get_in(@element.attributes, [:viewport, :clip?]), true)}
      scrollbars={string_value(get_in(@element.attributes, [:viewport, :scrollbars]), "auto")}
      width={string_optional(get_in(@element.attributes, [:viewport, :width]))}
      height={string_optional(get_in(@element.attributes, [:viewport, :height]))}
      sync_group={string_optional(get_in(@element.attributes, [:viewport, :sync_group]))}
      independent_scroll={boolean_default(get_in(@element.attributes, [:viewport, :independent_scroll?]), false)}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    >
      <%= for child <- child_elements(@element, :content) do %>
        <.render element={child} event_target={@event_target} />
      <% end %>
    </LiveUi.Widgets.Viewport.component>
    """
  end

  def render(%{element: %Element{kind: :scroll_bar}} = assigns) do
    ~H"""
    <LiveUi.Widgets.ScrollBar.component
      id={element_id(@element, "scroll-bar")}
      orientation={string_value(get_in(@element.attributes, [:scroll_bar, :orientation]), "vertical")}
      position_start={float_value(get_in(@element.attributes, [:scroll_bar, :position, :start]), 0.0)}
      position_end={float_value(get_in(@element.attributes, [:scroll_bar, :position, :end]), 0.0)}
      viewport_size={integer_optional(get_in(@element.attributes, [:scroll_bar, :viewport_size]))}
      content_size={integer_optional(get_in(@element.attributes, [:scroll_bar, :content_size]))}
      viewport_ref={string_optional(get_in(@element.attributes, [:scroll_bar, :viewport_ref]))}
      sync_group={string_optional(get_in(@element.attributes, [:scroll_bar, :sync_group]))}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
    />
    """
  end

  def render(%{element: %Element{kind: :split_pane}} = assigns) do
    ~H"""
    <LiveUi.Widgets.SplitPane.component
      id={element_id(@element, "split-pane")}
      direction={string_value(get_in(@element.attributes, [:split, :direction]), "horizontal")}
      ratio={float_value(get_in(@element.attributes, [:split, :ratio]), 0.5)}
      resizable={boolean_default(get_in(@element.attributes, [:split, :resizable?]), true)}
      min_primary={integer_optional(get_in(@element.attributes, [:split, :min_primary]))}
      min_secondary={integer_optional(get_in(@element.attributes, [:split, :min_secondary]))}
      divider_size={integer_optional(get_in(@element.attributes, [:split, :divider, :size]))}
      sync_scroll={string_optional(get_in(@element.attributes, [:split, :sync_scroll]))}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
    >
      <:primary :for={child <- child_elements(@element, :primary)}>
        <.render element={child} event_target={@event_target} />
      </:primary>
      <:secondary :for={child <- child_elements(@element, :secondary)}>
        <.render element={child} event_target={@event_target} />
      </:secondary>
    </LiveUi.Widgets.SplitPane.component>
    """
  end

  def render(%{element: %Element{kind: :canvas}} = assigns) do
    assigns = assign(assigns, :style_attrs, style_rest(assigns.element))

    ~H"""
    <LiveUi.Widgets.Canvas.component
      id={element_id(@element, "canvas")}
      operations={get_in(@element.attributes, [:canvas, :operations]) || []}
      width={integer_optional(get_in(@element.attributes, [:canvas, :width]))}
      height={integer_optional(get_in(@element.attributes, [:canvas, :height]))}
      unit={string_value(get_in(@element.attributes, [:canvas, :unit]), "cell")}
      background={string_optional(get_in(@element.attributes, [:canvas, :background]))}
      clip={boolean_default(get_in(@element.attributes, [:canvas, :clip?]), true)}
      tone={style_tone(@element)}
      variant={theme_variant(@element)}
      state={style_state(@element)}
      class={style_class(@element)}
      {@style_attrs}
    />
    """
  end

  def render(assigns) do
    ~H"""
    <div id={element_id(@element, "unsupported")} data-live-ui-widget="unsupported" data-live-ui-kind={to_string(@element.kind)}>
      Unsupported canonical kind: <%= inspect(@element.kind) %>
    </div>
    """
  end

  @spec namespace() :: module()
  def namespace, do: __MODULE__

  defp child_elements(%Element{} = element, slot \\ :default) do
    element
    |> Element.children_for_slot(slot)
    |> Enum.map(& &1.element)
    |> Enum.reject(&is_nil/1)
  end

  defp overlay_children(%Element{} = element) do
    element.children
    |> Enum.reject(&(&1.slot == :base))
    |> Enum.map(& &1.element)
    |> Enum.reject(&is_nil/1)
  end

  defp binding_name(%Element{} = element) do
    element
    |> primary_binding()
    |> case do
      %Binding{name: nil, path: [segment | _]} -> to_string(segment)
      %Binding{name: name} when not is_nil(name) -> to_string(name)
      _ -> element_id(element, "binding")
    end
  end

  defp binding_value(%Element{} = element) do
    case primary_binding(element) do
      %Binding{value: nil, default: default} -> default
      %Binding{value: value} -> value
      _ -> nil
    end
  end

  defp primary_binding(%Element{} = element) do
    element.attributes
    |> Map.get(:bindings, [])
    |> List.wrap()
    |> List.first()
  end

  defp primary_interaction(%Element{} = element, family) do
    element.attributes
    |> Map.get(:interactions, [])
    |> List.wrap()
    |> Enum.find(&match?(%Interaction{family: ^family}, &1))
  end

  defp interaction_event_attrs(%Element{} = element, event_target) do
    case {primary_action_interaction(element), event_target} do
      {%Interaction{} = interaction, target} when not is_nil(target) ->
        [
          {:"phx-click", "canonical_interaction"},
          {:"phx-target", target},
          {:"phx-value-interaction", encode_interaction(interaction)},
          {:"phx-value-element_id", element_id(element, "element")},
          {:"phx-value-widget", to_string(element.kind)}
        ]

      _ ->
        []
    end
  end

  defp primary_change_interaction(%Element{} = element) do
    primary_interaction(element, :change)
  end

  defp direct_change_interaction_attrs(%Element{} = element, event_target) do
    case {primary_change_interaction(element), event_target} do
      {%Interaction{} = interaction, target} when not is_nil(target) ->
        %{
          :"phx-input" => "canonical_change_interaction",
          :"phx-change" => "canonical_change_interaction",
          :"phx-target" => target,
          :"phx-value-change-interaction" => encode_interaction(interaction),
          :"phx-value-element_id" => element_id(element, Atom.to_string(element.kind)),
          :"phx-value-widget" => Atom.to_string(element.kind)
        }

      _ ->
        %{}
    end
  end

  defp encode_interaction(%Interaction{} = interaction) do
    interaction
    |> :erlang.term_to_binary()
    |> Base.url_encode64(padding: false)
  end

  defp selection_options(%Element{} = element) do
    element.attributes
    |> get_in([:selection, :options])
    |> List.wrap()
    |> Enum.map(fn option ->
      %{
        id: Map.get(option, :id) || Map.get(option, "id"),
        value: Map.get(option, :value) || Map.get(option, "value"),
        label: Map.get(option, :label) || Map.get(option, "label"),
        disabled: Map.get(option, :disabled?) || Map.get(option, "disabled?"),
        selected: Map.get(option, :selected?) || Map.get(option, "selected?")
      }
    end)
  end

  defp selection_multiple?(%Element{} = element, kind) do
    case kind do
      :radio_group -> false
      _ -> boolean_default(get_in(element.attributes, [:selection, :multiple?]), false)
    end
  end

  defp list_items(%Element{} = element, event_target) do
    element
    |> get_in([Access.key(:attributes), :list, :items])
    |> List.wrap()
    |> Enum.map(&normalize_list_item(&1, element, event_target))
  end

  defp navigation_items(%Element{} = element, event_target) do
    element
    |> get_in([Access.key(:attributes), :navigation, :items])
    |> List.wrap()
    |> Enum.map(&normalize_navigation_item(&1, element, event_target))
  end

  defp command_palette_items(%Element{} = element, event_target) do
    active_command = get_in(element.attributes, [:command_palette, :active_command])

    element
    |> get_in([Access.key(:attributes), :command_palette, :commands])
    |> List.wrap()
    |> Enum.map(fn command ->
      command = Map.new(command)
      command_id = Map.get(command, :id) || Map.get(command, "id")

      command
      |> Map.put(:active, command_id == active_command)
      |> maybe_put_item_attrs(collection_item_attrs(element, event_target, command_id))
    end)
  end

  defp segmented_button_group_options(%Element{} = element, event_target) do
    element.attributes
    |> get_in([:selection, :options])
    |> List.wrap()
    |> Enum.map(fn option ->
      option = Map.new(option)
      value = Map.get(option, :value, Map.get(option, "value"))
      disabled? = Map.get(option, :disabled?, Map.get(option, "disabled?"))

      %{
        value: value,
        label: Map.get(option, :label, Map.get(option, "label", "")),
        disabled?: disabled?,
        attrs: segmented_button_group_option_attrs(element, event_target, value, disabled?)
      }
    end)
  end

  defp segmented_button_group_option_attrs(_element, _event_target, _value, true), do: %{}

  defp segmented_button_group_option_attrs(%Element{} = element, event_target, value, _disabled?) do
    case {segmented_button_group_interaction(element), event_target, value} do
      {%Interaction{} = interaction, target, option_value}
      when not is_nil(target) and not is_nil(option_value) ->
        %{
          :"phx-click" => "canonical_interaction",
          :"phx-target" => target,
          :"phx-value-interaction" => encode_interaction(interaction),
          :"phx-value-element_id" => element_id(element, "segmented-button-group"),
          :"phx-value-widget" => "segmented_button_group",
          :"phx-value-value" => to_string(option_value),
          :"phx-value-selected_value" => to_string(option_value)
        }

      _ ->
        %{}
    end
  end

  defp segmented_button_group_interaction(%Element{} = element) do
    primary_control_interaction(element) ||
      case selection_intent(element) do
        nil ->
          nil

        intent ->
          Interaction.selection(
            intent: intent,
            element_id: element_id(element, "segmented-button-group"),
            mapping: %{selected_value: :value}
          )
      end
  end

  defp selection_intent(%Element{} = element) do
    selection = Map.get(element.attributes, :selection, %{})
    Map.get(selection, :selection_intent, Map.get(selection, "selection_intent"))
  end

  defp selection_active_value(%Element{} = element) do
    selection = Map.get(element.attributes, :selection, %{})

    Map.get(
      selection,
      :active_value,
      Map.get(
        selection,
        "active_value",
        Map.get(selection, :selected_value, Map.get(selection, "selected_value"))
      )
    )
  end

  defp segmented_button_group_label(%Element{} = element) do
    get_in(element.attributes, [:accessibility, :label]) ||
      get_in(element.attributes, [:selection, :label]) ||
      metadata_description(element) ||
      "Segmented control"
  end

  defp collection_picker_attributes(%Element{} = element) do
    element.attributes
    |> Map.get(:collection_picker, Map.get(element.attributes, "collection_picker", %{}))
    |> normalize_panel()
  end

  defp collection_picker_filters(picker) do
    picker
    |> map_value(:filters, [])
    |> List.wrap()
    |> Enum.map(&normalize_panel/1)
  end

  defp collection_picker_items(picker) do
    picker
    |> map_value(:items, [])
    |> List.wrap()
    |> Enum.map(&normalize_panel/1)
  end

  defp collection_picker_suggestions(picker) do
    picker
    |> map_value(:suggestions, [])
    |> List.wrap()
    |> Enum.map(&normalize_panel/1)
  end

  defp collection_picker_query_attrs(%Element{} = element, event_target) do
    case {primary_interaction(element, :change), event_target} do
      {%Interaction{} = interaction, target} when not is_nil(target) ->
        %{
          :"phx-input" => "canonical_change_interaction",
          :"phx-change" => "canonical_change_interaction",
          :"phx-target" => target,
          :"phx-value-change-interaction" => encode_interaction(interaction),
          :"phx-value-element_id" => element_id(element, "collection-picker"),
          :"phx-value-widget" => "collection_picker"
        }

      _ ->
        %{}
    end
  end

  defp collection_picker_filter_attrs(%Element{} = element, event_target, picker) do
    picker
    |> collection_picker_filters()
    |> Map.new(fn filter ->
      {collection_picker_entry_key(filter),
       collection_picker_command_attrs(element, event_target, filter, :toggle_filter, :filter_id)}
    end)
  end

  defp collection_picker_item_attrs(%Element{} = element, event_target, picker) do
    picker
    |> collection_picker_items()
    |> Map.new(fn item ->
      {collection_picker_entry_key(item),
       collection_picker_selection_attrs(element, event_target, item)}
    end)
  end

  defp collection_picker_suggestion_attrs(%Element{} = element, event_target, picker, command) do
    picker
    |> collection_picker_suggestions()
    |> Map.new(fn suggestion ->
      {collection_picker_entry_key(suggestion),
       collection_picker_command_attrs(element, event_target, suggestion, command, :suggestion_id)}
    end)
  end

  defp collection_picker_selection_attrs(%Element{} = element, event_target, item) do
    item_id = collection_picker_entry_id(item)

    if collection_picker_entry_disabled?(item) do
      %{}
    else
      case {primary_interaction(element, :selection), event_target, item_id} do
        {%Interaction{} = interaction, target, id} when not is_nil(target) and not is_nil(id) ->
          %{
            :"phx-click" => "canonical_interaction",
            :"phx-target" => target,
            :"phx-value-interaction" => encode_interaction(interaction),
            :"phx-value-element_id" => element_id(element, "collection-picker"),
            :"phx-value-widget" => "collection_picker",
            :"phx-value-item_id" => to_string(id),
            :"phx-value-selected_value" => to_string(id)
          }

        _ ->
          %{}
      end
    end
  end

  defp collection_picker_command_attrs(
         %Element{} = element,
         event_target,
         entry,
         command,
         id_attr
       ) do
    entry_id = collection_picker_entry_id(entry)

    if collection_picker_entry_disabled?(entry) do
      %{}
    else
      case {collection_picker_command_interaction(element, command), event_target, entry_id} do
        {%Interaction{} = interaction, target, id} when not is_nil(target) and not is_nil(id) ->
          %{
            :"phx-click" => "canonical_interaction",
            :"phx-target" => target,
            :"phx-value-interaction" => encode_interaction(interaction),
            :"phx-value-element_id" => element_id(element, "collection-picker"),
            :"phx-value-widget" => "collection_picker",
            :"phx-value-command" => to_string(command),
            String.to_atom("phx-value-#{id_attr}") => to_string(id)
          }

        _ ->
          %{}
      end
    end
  end

  defp collection_picker_command_interaction(%Element{} = element, command) do
    element.attributes
    |> Map.get(:interactions, [])
    |> List.wrap()
    |> Enum.find(fn
      %Interaction{family: :command, payload: payload} ->
        map_value(payload, :command) == command or
          to_string(map_value(payload, :command)) == to_string(command)

      _interaction ->
        false
    end)
  end

  defp collection_picker_entry_id(entry), do: map_value(entry, :id)

  defp collection_picker_entry_key(entry),
    do: entry |> collection_picker_entry_id() |> normalize_key()

  defp collection_picker_entry_disabled?(entry) do
    map_value(entry, :disabled?) || map_value(entry, :disabled) || false
  end

  defp diff_banner_attributes(%Element{} = element) do
    element.attributes
    |> Map.get(:diff, Map.get(element.attributes, "diff", %{}))
    |> normalize_panel()
  end

  defp diff_banner_chips(%Element{} = element, event_target) do
    diff = diff_banner_attributes(element)

    [
      {:all, "all", diff_banner_total(diff)},
      {:new, "new", map_value(diff, :new_count, 0)},
      {:changed, "changed", map_value(diff, :changed_count, 0)},
      {:removed, "removed", map_value(diff, :removed_count, 0)}
    ]
    |> Enum.map(fn {kind, label, count} ->
      %{
        kind: kind,
        label: label,
        count: count,
        attrs: diff_banner_chip_attrs(element, event_target, kind)
      }
    end)
  end

  defp diff_banner_total(diff) do
    map_value(diff, :new_count, 0) + map_value(diff, :changed_count, 0) +
      map_value(diff, :removed_count, 0)
  end

  defp diff_banner_chip_attrs(%Element{} = element, event_target, filter) do
    case {diff_banner_filter_interaction(element), event_target, filter} do
      {%Interaction{} = interaction, target, selected_filter} when not is_nil(target) ->
        %{
          :"phx-click" => "canonical_interaction",
          :"phx-target" => target,
          :"phx-value-interaction" => encode_interaction(interaction),
          :"phx-value-element_id" => element_id(element, "diff-banner"),
          :"phx-value-widget" => "diff_banner",
          :"phx-value-filter" => to_string(selected_filter),
          :"phx-value-value" => to_string(selected_filter),
          :"phx-value-selected_value" => to_string(selected_filter)
        }

      _ ->
        %{}
    end
  end

  defp diff_banner_filter_interaction(%Element{} = element) do
    primary_control_interaction(element) ||
      case diff_banner_filter_intent(element) do
        nil ->
          nil

        intent ->
          Interaction.selection(
            intent: intent,
            element_id: element_id(element, "diff-banner"),
            mapping: %{selected_value: :filter}
          )
      end
  end

  defp diff_banner_filter_intent(%Element{} = element) do
    diff = diff_banner_attributes(element)
    map_value(diff, :filter_intent, map_value(diff, :selection_intent))
  end

  defp context_selector_attributes(%Element{} = element) do
    element.attributes
    |> Map.get(:context_selector, Map.get(element.attributes, "context_selector", %{}))
    |> normalize_panel()
  end

  defp context_selector_groups(%Element{} = element, event_target) do
    selector = context_selector_attributes(element)

    selector
    |> map_value(:groups, [])
    |> List.wrap()
    |> Enum.map(&context_selector_group(&1, element, event_target))
  end

  defp context_selector_group(group, element, event_target) do
    group = normalize_panel(group)
    group_id = map_value(group, :id, map_value(group, :group_id, "context"))

    %{
      id: group_id,
      label: map_value(group, :label, map_value(group, :group_label, group_id)),
      items:
        group
        |> map_value(:items, [])
        |> List.wrap()
        |> Enum.map(&context_selector_item(&1, element, event_target, group_id))
    }
    |> maybe_put_item_value(:description, map_value(group, :description))
    |> maybe_put_item_value(:metadata, map_value(group, :metadata))
  end

  defp context_selector_item(item, element, event_target, group_id) do
    item = normalize_panel(item)
    value = map_value(item, :value, map_value(item, :id))
    disabled? = map_value(item, :disabled?, map_value(item, :disabled, false))

    %{
      id: map_value(item, :id, value),
      value: value,
      label: map_value(item, :label, value),
      disabled?: disabled?,
      attrs: context_selector_item_attrs(element, event_target, group_id, value, disabled?)
    }
    |> maybe_put_item_value(:description, map_value(item, :description))
    |> maybe_put_item_value(:selected?, map_value(item, :selected?))
    |> maybe_put_item_value(:metadata, map_value(item, :metadata))
  end

  defp context_selector_item_attrs(_element, _event_target, _group_id, _value, true), do: %{}

  defp context_selector_item_attrs(
         %Element{} = element,
         event_target,
         group_id,
         value,
         _disabled?
       ) do
    case {context_selector_interaction(element), event_target, group_id, value} do
      {%Interaction{} = interaction, target, item_group_id, item_value}
      when not is_nil(target) and not is_nil(item_value) ->
        %{
          :"phx-click" => "canonical_interaction",
          :"phx-target" => target,
          :"phx-value-interaction" => encode_interaction(interaction),
          :"phx-value-element_id" => element_id(element, "context-selector"),
          :"phx-value-widget" => "context_selector",
          :"phx-value-group_id" => to_string(item_group_id),
          :"phx-value-value" => to_string(item_value),
          :"phx-value-selected_value" => to_string(item_value)
        }

      _ ->
        %{}
    end
  end

  defp context_selector_interaction(%Element{} = element) do
    primary_control_interaction(element) ||
      case context_selector_selection_intent(element) do
        nil ->
          nil

        intent ->
          Interaction.selection(
            intent: intent,
            element_id: element_id(element, "context-selector"),
            mapping: %{selected_value: :value}
          )
      end
  end

  defp context_selector_selection_intent(%Element{} = element) do
    element
    |> context_selector_attributes()
    |> map_value(:selection_intent)
  end

  defp file_tree_attributes(%Element{} = element) do
    element.attributes
    |> Map.get(:file_tree, Map.get(element.attributes, "file_tree", %{}))
    |> normalize_panel()
  end

  defp file_tree_nodes(%Element{} = element, event_target) do
    element
    |> file_tree_attributes()
    |> map_value(:nodes, [])
    |> List.wrap()
    |> Enum.map(&file_tree_node(&1, element, event_target))
  end

  defp file_tree_node(node, element, event_target) do
    node = normalize_panel(node)

    case file_tree_node_type(map_value(node, :type, :file_leaf)) do
      :folder ->
        node
        |> Map.put(:type, :folder)
        |> Map.put(:children, file_tree_child_nodes(node, element, event_target))
        |> maybe_put_node_attrs(
          :toggle_attrs,
          file_tree_toggle_attrs(element, event_target, node)
        )

      :file_leaf ->
        node
        |> Map.put(:type, :file_leaf)
        |> maybe_put_node_attrs(
          :select_attrs,
          file_tree_select_attrs(element, event_target, node)
        )
    end
  end

  defp file_tree_child_nodes(node, element, event_target) do
    node
    |> map_value(:children, [])
    |> List.wrap()
    |> Enum.map(&file_tree_node(&1, element, event_target))
  end

  defp file_tree_node_type(type) when type in [:folder, "folder", :directory, "directory"],
    do: :folder

  defp file_tree_node_type(_type), do: :file_leaf

  defp file_tree_select_attrs(%Element{} = element, event_target, node) do
    case {file_tree_selection_interaction(element), event_target, file_tree_node_id(node),
          file_tree_node_path(node)} do
      {%Interaction{} = interaction, target, id, path}
      when not is_nil(target) and not is_nil(path) ->
        %{
          :"phx-click" => "canonical_interaction",
          :"phx-target" => target,
          :"phx-value-interaction" => encode_interaction(interaction),
          :"phx-value-element_id" => element_id(element, "file-tree-browser"),
          :"phx-value-widget" => "file_tree_browser",
          :"phx-value-node_id" => to_string(id || path),
          :"phx-value-path" => to_string(path),
          :"phx-value-selected_value" => to_string(path)
        }

      _ ->
        %{}
    end
  end

  defp file_tree_toggle_attrs(%Element{} = element, event_target, node) do
    default_expanded? =
      element
      |> file_tree_attributes()
      |> map_value(:default_expanded?, true)
      |> boolean_default(true)

    expanded? = file_tree_node_expanded?(node, default_expanded?)

    case {file_tree_toggle_interaction(element), event_target, file_tree_node_id(node),
          not expanded?} do
      {%Interaction{} = interaction, target, id, next_expanded?}
      when not is_nil(target) and not is_nil(id) ->
        %{
          :"phx-click" => "canonical_change_interaction",
          :"phx-target" => target,
          :"phx-value-change-interaction" => encode_interaction(interaction),
          :"phx-value-element_id" => element_id(element, "file-tree-browser"),
          :"phx-value-widget" => "file_tree_browser",
          :"phx-value-node_id" => to_string(id),
          :"phx-value-expanded" => to_string(next_expanded?)
        }

      _ ->
        %{}
    end
  end

  defp file_tree_selection_interaction(%Element{} = element) do
    primary_interaction(element, :selection) ||
      case file_tree_intent(element, :selection_intent) do
        nil ->
          nil

        intent ->
          Interaction.selection(
            intent: intent,
            element_id: element_id(element, "file-tree-browser"),
            mapping: %{node_id: :node_id, selected_path: :path, selected_value: :path}
          )
      end
  end

  defp file_tree_toggle_interaction(%Element{} = element) do
    primary_interaction(element, :change) ||
      case file_tree_intent(element, :toggle_intent) do
        nil ->
          nil

        intent ->
          Interaction.change(
            intent: intent,
            element_id: element_id(element, "file-tree-browser"),
            mapping: %{node_id: :node_id, expanded?: :expanded}
          )
      end
  end

  defp file_tree_intent(%Element{} = element, key) do
    element
    |> file_tree_attributes()
    |> map_value(key)
  end

  defp file_tree_node_id(node), do: map_value(node, :id, file_tree_node_path(node))
  defp file_tree_node_path(node), do: map_value(node, :path, file_tree_node_id_fallback(node))
  defp file_tree_node_id_fallback(node), do: map_value(node, :id)

  defp file_tree_node_expanded?(node, default) do
    case map_value(node, :expanded?) do
      nil -> default
      value -> value in [true, "true", 1, "1", "yes", "open"]
    end
  end

  defp maybe_put_node_attrs(node, _key, attrs) when attrs == %{}, do: node
  defp maybe_put_node_attrs(node, key, attrs), do: Map.put(node, key, attrs)

  defp metadata_description(%Element{metadata: %{description: description}}), do: description
  defp metadata_description(_element), do: nil

  defp rail_attributes(%Element{} = element) do
    element.attributes
    |> Map.get(:rail, Map.get(element.attributes, "rail", %{}))
    |> case do
      rail when is_map(rail) -> rail
      rail when is_list(rail) -> Map.new(rail)
      _other -> %{}
    end
  end

  defp query_preview_attributes(%Element{} = element) do
    element.attributes
    |> Map.get(:query_preview, Map.get(element.attributes, "query_preview", %{}))
    |> case do
      preview when is_map(preview) -> preview
      preview when is_list(preview) -> Map.new(preview)
      _other -> %{}
    end
  end

  defp query_preview_action_attrs(%Element{} = element, event_target, preview) do
    query = map_value(preview, :query)

    %{
      dismiss:
        query_preview_interaction_attrs(
          element,
          event_target,
          primary_interaction(element, :close),
          query
        ),
      open:
        query_preview_interaction_attrs(
          element,
          event_target,
          primary_interaction(element, :open),
          query
        ),
      save:
        query_preview_interaction_attrs(
          element,
          event_target,
          primary_interaction(element, :command),
          query
        )
    }
  end

  defp query_preview_interaction_attrs(
         %Element{} = element,
         event_target,
         %Interaction{} = interaction,
         query
       )
       when not is_nil(event_target) do
    %{
      :"phx-click" => "canonical_interaction",
      :"phx-target" => event_target,
      :"phx-value-interaction" => encode_interaction(interaction),
      :"phx-value-element_id" => element_id(element, "composer-query-preview"),
      :"phx-value-widget" => "composer_query_preview",
      :"phx-value-query" => to_string(query || "")
    }
  end

  defp query_preview_interaction_attrs(_element, _event_target, _interaction, _query), do: %{}

  defp right_rail_panels(rail) do
    rail
    |> map_value(:panels, [])
    |> List.wrap()
    |> Enum.map(&normalize_panel/1)
  end

  defp right_rail_active_panel(rail, panels) do
    map_value(rail, :active_panel) || panels |> List.first() |> rail_panel_id()
  end

  defp right_rail_panel_attrs(%Element{} = element, event_target, panels) do
    Map.new(panels, fn panel ->
      {rail_panel_key(panel), right_rail_panel_interaction_attrs(element, event_target, panel)}
    end)
  end

  defp right_rail_panel_interaction_attrs(%Element{} = element, event_target, panel) do
    panel_id = rail_panel_id(panel)

    if rail_panel_disabled?(panel) do
      %{}
    else
      case {primary_interaction(element, :selection), event_target, panel_id} do
        {%Interaction{} = interaction, target, id} when not is_nil(target) and not is_nil(id) ->
          %{
            :"phx-click" => "canonical_interaction",
            :"phx-target" => target,
            :"phx-value-interaction" => encode_interaction(interaction),
            :"phx-value-element_id" => element_id(element, "right-rail"),
            :"phx-value-widget" => "right_rail",
            :"phx-value-panel_id" => to_string(id),
            :"phx-value-selected_value" => to_string(id)
          }

        _ ->
          %{}
      end
    end
  end

  defp right_rail_collapse_attrs(%Element{} = element, event_target) do
    case {primary_interaction(element, :change), event_target} do
      {%Interaction{} = interaction, target} when not is_nil(target) ->
        %{
          :"phx-click" => "canonical_change_interaction",
          :"phx-target" => target,
          :"phx-value-change-interaction" => encode_interaction(interaction),
          :"phx-value-element_id" => element_id(element, "right-rail"),
          :"phx-value-widget" => "right_rail"
        }

      _ ->
        %{}
    end
  end

  defp rail_panel_children(%Element{} = element, panel) do
    slot = rail_panel_slot(panel)

    element.children
    |> Enum.filter(&(to_string(&1.slot) == to_string(slot)))
    |> Enum.map(& &1.element)
    |> Enum.reject(&is_nil/1)
  end

  defp rail_panel_slot(panel), do: map_value(panel, :content_slot, rail_panel_id(panel))
  defp rail_panel_id(nil), do: nil
  defp rail_panel_id(panel), do: map_value(panel, :id)

  defp rail_panel_disabled?(panel) do
    map_value(panel, :disabled?) || map_value(panel, :disabled) || false
  end

  defp rail_panel_key(panel) do
    panel
    |> rail_panel_id()
    |> normalize_key()
  end

  defp normalize_panel(panel) when is_map(panel), do: Map.new(panel)
  defp normalize_panel(panel) when is_list(panel), do: Map.new(panel)
  defp normalize_panel(panel), do: %{id: panel, label: panel}

  defp map_value(map, key, default \\ nil)
  defp map_value(nil, _key, default), do: default

  defp map_value(map, key, default) when is_map(map),
    do: Map.get(map, key, Map.get(map, to_string(key), default))

  defp map_value(list, key, default) when is_list(list), do: Keyword.get(list, key, default)
  defp map_value(_other, _key, default), do: default

  defp normalize_key(nil), do: "panel"

  defp normalize_key(value) do
    value
    |> to_string()
    |> String.replace(~r/[^a-zA-Z0-9_-]+/, "-")
  end

  defp context_menu_items(%Element{} = element, event_target) do
    element
    |> child_elements(:menu)
    |> List.first()
    |> case do
      %Element{} = menu ->
        menu
        |> get_in([Access.key(:attributes), :navigation, :items])
        |> List.wrap()
        |> Enum.map(&normalize_navigation_item(&1, element, event_target))

      _ ->
        []
    end
  end

  defp table_rows(%Element{} = element, event_target) do
    element
    |> get_in([Access.key(:attributes), :table, :rows])
    |> List.wrap()
    |> Enum.map(&normalize_table_row(&1, element, event_target))
  end

  defp tree_nodes(%Element{} = element, event_target) do
    element
    |> get_in([Access.key(:attributes), :tree, :nodes])
    |> List.wrap()
    |> Enum.map(&normalize_tree_node(&1, element, event_target))
  end

  defp chart_values(%Element{} = element) do
    case get_in(element.attributes, [:chart, :series]) || [] do
      [series | _] -> Map.get(series, :values) || Map.get(series, "values") || []
      _ -> []
    end
  end

  defp theme_variant(%Element{} = element), do: element |> style_profile() |> Map.get(:variant)
  defp style_tone(%Element{} = element), do: element |> style_profile() |> Map.get(:tone)
  defp style_state(%Element{} = element), do: element |> style_profile() |> Map.get(:state)
  defp style_class(%Element{} = element), do: element |> style_profile() |> Map.get(:class)

  defp style_rest(%Element{} = element),
    do: element |> style_profile() |> NativeStyle.to_assigns() |> Map.get(:rest, %{})

  defp style_profile(%Element{} = element) do
    NativeStyle.from_element(element)
  end

  defp merge_global_attrs(left, right) do
    normalize_global_attrs(left)
    |> Map.merge(normalize_global_attrs(right), fn
      "style", left_value, right_value -> merge_inline_styles(left_value, right_value)
      _key, _left_value, right_value -> right_value
    end)
  end

  defp normalize_global_attrs(attrs) when is_list(attrs) do
    Map.new(attrs, fn {key, value} -> {to_string(key), to_string(value)} end)
  end

  defp normalize_global_attrs(attrs) when is_map(attrs) do
    Map.new(attrs, fn {key, value} -> {to_string(key), to_string(value)} end)
  end

  defp normalize_global_attrs(_other), do: %{}

  defp merge_inline_styles(left, right) do
    [left, right]
    |> Enum.map(&normalize_optional_style/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.join("; ")
    |> normalize_optional_style()
  end

  defp normalize_optional_style(nil), do: nil
  defp normalize_optional_style(""), do: nil
  defp normalize_optional_style(value), do: value |> to_string() |> String.trim()

  defp accessibility_attrs(%Element{} = element) do
    accessibility = Map.get(element.attributes, :accessibility, %{})

    []
    |> maybe_attr(:role, accessibility[:role] || accessibility["role"])
    |> maybe_attr(:"aria-label", accessibility[:label] || accessibility["label"])
    |> maybe_attr(
      :"aria-labelledby",
      accessibility[:labelled_by] || accessibility["labelled_by"]
    )
    |> maybe_attr(
      :"aria-describedby",
      accessibility[:described_by] || accessibility["described_by"]
    )
    |> maybe_attr(:"aria-live", accessibility[:live] || accessibility["live"])
    |> maybe_attr(:"aria-atomic", boolean_attr(accessibility[:atomic] || accessibility["atomic"]))
  end

  defp content_text(%Element{} = element) do
    string_value(get_in(element.attributes, [:content, :text]), "")
  end

  defp label_for(%Element{} = element) do
    string_optional(get_in(element.attributes, [:label, :for]))
  end

  defp avatar_size_variant(:small), do: :small
  defp avatar_size_variant(:medium), do: :medium
  defp avatar_size_variant(:large), do: :large
  defp avatar_size_variant("small"), do: :small
  defp avatar_size_variant("medium"), do: :medium
  defp avatar_size_variant("large"), do: :large
  defp avatar_size_variant(_other), do: :small

  defp input_type(:text_input), do: "text"
  defp input_type(:numeric_input), do: "number"
  defp input_type(:date_input), do: "date"
  defp input_type(:time_input), do: "time"
  defp input_type(:file_input), do: "file"

  defp element_id(%Element{id: nil}, fallback), do: fallback
  defp element_id(%Element{id: id}, _fallback), do: to_string(id)

  defp string_value(nil, default), do: default
  defp string_value(value, _default), do: to_string(value)

  defp string_optional(nil), do: nil
  defp string_optional(value), do: to_string(value)

  defp last_activity_label(nil), do: nil

  defp last_activity_label(%DateTime{} = dt) do
    now = DateTime.utc_now()
    diff_seconds = DateTime.diff(now, dt, :second)

    cond do
      diff_seconds < 60 -> "just now"
      diff_seconds < 3600 -> "#{div(diff_seconds, 60)}m ago"
      diff_seconds < 86_400 -> "#{div(diff_seconds, 3600)}h ago"
      true -> "#{div(diff_seconds, 86_400)}d ago"
    end
  end

  defp last_activity_label(_other), do: nil

  defp dependency_labels(edges) when is_list(edges) do
    Enum.map(edges, fn
      edge when is_map(edge) ->
        edge
        |> Map.get(:label, Map.get(edge, :id))
        |> to_string()

      edge ->
        to_string(edge)
    end)
  end

  defp dependency_labels(_edges), do: []

  defp interaction_intent(%Interaction{intent: nil}, default), do: default
  defp interaction_intent(%Interaction{intent: intent}, _default), do: intent
  defp interaction_intent(_interaction, default), do: default

  defp boolean_attr(true), do: "true"
  defp boolean_attr(false), do: "false"
  defp boolean_attr(nil), do: nil

  defp placement_value(nil, default), do: default

  defp placement_value(value, _default) do
    value
    |> to_string()
    |> String.replace("_", "-")
  end

  defp integer_optional(nil), do: nil
  defp integer_optional(value) when is_integer(value), do: value
  defp integer_optional(value) when is_float(value), do: trunc(value)
  defp integer_optional(value) when is_binary(value), do: String.to_integer(value)

  defp integer_value(nil, default), do: default
  defp integer_value(value, _default) when is_integer(value), do: value
  defp integer_value(value, _default) when is_float(value), do: trunc(value)
  defp integer_value(value, _default) when is_binary(value), do: String.to_integer(value)

  defp float_value(nil, default), do: default
  defp float_value(value, _default) when is_float(value), do: value
  defp float_value(value, _default) when is_integer(value), do: value / 1

  defp float_value(value, default) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _ -> default
    end
  end

  defp boolean_default(nil, default), do: default
  defp boolean_default(value, _default) when is_boolean(value), do: value
  defp boolean_default("true", _default), do: true
  defp boolean_default("false", _default), do: false
  defp boolean_default(value, _default), do: value

  defp state_boolean(%Element{} = element, path) when is_list(path) do
    boolean_default(get_in(element.attributes, path), false)
  end

  defp state_boolean(%Element{} = element, key) do
    boolean_default(get_in(element.attributes, [:state, key]), false)
  end

  defp form_interaction_attrs(%Element{} = element, event_target) do
    case event_target do
      target when is_binary(target) ->
        %{}
        |> maybe_merge_form_interaction(
          primary_control_interaction(element),
          element,
          target,
          :"phx-change",
          "canonical_change_interaction",
          :"phx-value-change-interaction"
        )
        |> maybe_merge_form_interaction(
          primary_submit_interaction(element),
          element,
          target,
          :"phx-submit",
          "canonical_submit_interaction",
          :"phx-value-submit-interaction"
        )

      _other ->
        %{}
    end
  end

  defp maybe_merge_form_interaction(
         attrs,
         %Interaction{} = interaction,
         %Element{} = element,
         target,
         event_attr,
         event_name,
         value_attr
       ) do
    Map.merge(attrs, %{
      event_attr => event_name,
      :"phx-target" => target,
      value_attr => encode_interaction(interaction),
      :"phx-value-widget" => Atom.to_string(element.kind),
      :"phx-value-element_id" => element_id(element, Atom.to_string(element.kind))
    })
  end

  defp maybe_merge_form_interaction(
         attrs,
         nil,
         _element,
         _target,
         _event_attr,
         _event_name,
         _value_attr
       ),
       do: attrs

  defp maybe_attr(attrs, _key, nil), do: attrs
  defp maybe_attr(attrs, _key, ""), do: attrs
  defp maybe_attr(attrs, key, value), do: [{key, value} | attrs]

  defp primary_action_interaction(%Element{} = element) do
    primary_interaction(element, :click) ||
      primary_interaction(element, :open) ||
      primary_interaction(element, :navigation) ||
      primary_interaction(element, :command)
  end

  defp primary_collection_interaction(%Element{} = element) do
    primary_interaction(element, :selection) ||
      primary_interaction(element, :click) ||
      primary_interaction(element, :navigation) ||
      primary_interaction(element, :command)
  end

  defp collection_item_attrs(%Element{} = element, event_target, item_id) do
    case {primary_collection_interaction(element), event_target, item_id} do
      {%Interaction{} = interaction, target, id} when not is_nil(target) and not is_nil(id) ->
        %{
          :"phx-click" => "canonical_interaction",
          :"phx-target" => target,
          :"phx-value-interaction" => encode_interaction(interaction),
          :"phx-value-element_id" => element_id(element, Atom.to_string(element.kind)),
          :"phx-value-widget" => Atom.to_string(element.kind),
          :"phx-value-item_id" => to_string(id)
        }

      _ ->
        %{}
    end
  end

  defp normalize_navigation_item(item, source_element, event_target) do
    item = Map.new(item)
    item_id = Map.get(item, :id) || Map.get(item, "id")

    item
    |> Map.put(:disabled, Map.get(item, :disabled, Map.get(item, :disabled?)))
    |> Map.put(:active, Map.get(item, :active, Map.get(item, :active?)))
    |> maybe_put_item_attrs(collection_item_attrs(source_element, event_target, item_id))
  end

  defp normalize_list_item(item, source_element, event_target) do
    item = Map.new(item)
    item_id = Map.get(item, :id) || Map.get(item, "id")

    item
    |> Map.put(:selected, Map.get(item, :selected, Map.get(item, :selected?)))
    |> maybe_put_item_attrs(collection_item_attrs(source_element, event_target, item_id))
  end

  defp normalize_table_row(row, source_element, event_target) do
    row = Map.new(row)
    row_id = Map.get(row, :id) || Map.get(row, "id")

    row
    |> Map.put(:selected, Map.get(row, :selected, Map.get(row, :selected?)))
    |> maybe_put_item_attrs(collection_item_attrs(source_element, event_target, row_id))
  end

  defp normalize_tree_node(node, source_element, event_target) do
    node = Map.new(node)
    node_id = Map.get(node, :id) || Map.get(node, "id")

    children =
      node
      |> Map.get(:children, Map.get(node, "children", []))
      |> List.wrap()
      |> Enum.map(&normalize_tree_node(&1, source_element, event_target))

    node
    |> Map.put(:selected, Map.get(node, :selected, Map.get(node, :selected?)))
    |> Map.put(:expanded, Map.get(node, :expanded, Map.get(node, :expanded?)))
    |> Map.put(:children, children)
    |> maybe_put_item_attrs(collection_item_attrs(source_element, event_target, node_id))
  end

  defp maybe_put_item_attrs(item, attrs) when attrs == %{}, do: item

  defp maybe_put_item_attrs(item, attrs) do
    Map.update(item, :attrs, attrs, &Map.merge(Map.new(&1), attrs))
  end

  defp maybe_put_item_value(item, _key, nil), do: item
  defp maybe_put_item_value(item, key, value), do: Map.put(item, key, value)

  defp primary_control_interaction(%Element{} = element) do
    primary_interaction(element, :change) || primary_interaction(element, :selection)
  end

  defp primary_submit_interaction(%Element{} = element) do
    primary_interaction(element, :submit)
  end

  defp interaction_form_id(%Element{} = element, widget_name) when is_binary(widget_name) do
    "#{element_id(element, widget_name)}-interaction-form"
  end

  @artifact_row_kinds [:pr, :doc, :spec, :file, :grain, :generic]

  defp artifact_row_kind(nil), do: :generic
  defp artifact_row_kind(kind) when kind in @artifact_row_kinds, do: kind
  defp artifact_row_kind(kind) when is_atom(kind), do: :generic

  defp artifact_row_kind(kind) when is_binary(kind) do
    atom = String.to_existing_atom(kind)
    if atom in @artifact_row_kinds, do: atom, else: :generic
  rescue
    ArgumentError -> :generic
  end

  defp artifact_row_counts(nil), do: []
  defp artifact_row_counts(counts) when is_list(counts), do: counts

  defp artifact_row_counts(counts) when is_map(counts) do
    counts
    |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
    |> Enum.map(fn {key, value} -> %{key: key, value: value} end)
  end

  defp artifact_row_counts(_other), do: []
end
