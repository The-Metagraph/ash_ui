defmodule UnifiedUi.Compiler.Pipeline do
  @moduledoc """
  Compiler passes and lowering helpers for deterministic `UnifiedUi` to
  `UnifiedIUR` compilation.
  """

  alias Spark.Dsl.Extension

  alias UnifiedIUR.{
    Container,
    Element,
    Forms,
    Interaction,
    Layout,
    Metadata,
    Style,
    Theme,
    Widgets
  }

  alias UnifiedIUR.Binding, as: IURBinding
  alias UnifiedUi.Compiler.Result
  alias UnifiedUi.Dsl.Node
  alias UnifiedUi.{Signal, Signals}

  @type context :: %{
          module: module(),
          identity: map(),
          composition: map(),
          default_theme: atom() | String.t() | nil,
          top_level_nodes: [Node.t()],
          node_by_id: %{optional(atom()) => Node.t()},
          authored_themes: [UnifiedUi.Theme.t()],
          compiled_themes: [Theme.t()],
          compiled_theme_by_id: %{optional(atom()) => Theme.t()},
          theme_style_by_id: %{optional(atom()) => Style.t()},
          binding_by_id: %{optional(atom()) => UnifiedIUR.Binding.t()},
          interaction_by_id: %{optional(atom()) => UnifiedIUR.Interaction.t()},
          authored_ids: [atom()]
        }

  @spec run(module(), keyword() | map()) :: Result.t()
  def run(module, _opts \\ []) when is_atom(module) do
    context = build_context(module)
    theme_bundle = compile_themes(context.authored_themes)
    compiled_themes = theme_bundle.themes
    compiled_theme_by_id = theme_bundle.by_id
    compiled_bindings = compile_bindings(Signals.bindings(module))
    binding_by_id = Map.new(compiled_bindings, &{&1.name, &1})
    compiled_interactions = compile_interactions(Signals.interactions(module), binding_by_id)
    interaction_by_id = Map.new(compiled_interactions, &{interaction_identifier(&1), &1})

    context =
      context
      |> Map.put(:compiled_themes, compiled_themes)
      |> Map.put(:compiled_theme_by_id, compiled_theme_by_id)
      |> Map.put(:theme_style_by_id, theme_bundle.style_by_id)
      |> Map.put(:binding_by_id, binding_by_id)
      |> Map.put(:interaction_by_id, interaction_by_id)

    iur =
      Element.new(:composite, context.composition.mode,
        id: context.composition.root,
        metadata: root_metadata(context),
        attributes: root_attributes(context, compiled_bindings, compiled_interactions),
        children:
          Enum.map(context.top_level_nodes, fn node ->
            Element.Child.new(:default, lower_node(node, context, MapSet.new()))
          end)
      )

    %Result{
      module: module,
      identity: context.identity,
      composition: context.composition,
      iur: iur,
      themes: compiled_themes,
      default_theme: context.default_theme,
      bindings: compiled_bindings,
      interactions: compiled_interactions,
      trace: %{
        authored_ids: context.authored_ids,
        binding_by_id: binding_by_id,
        interaction_by_id: interaction_by_id,
        theme_by_id: compiled_theme_by_id
      }
    }
  end

  defp build_context(module) do
    top_level_nodes = Extension.get_entities(module, [:composition])
    authored_themes = UnifiedUi.Theme.themes(module)

    %{
      module: module,
      identity: %{
        id: Extension.get_opt(module, [:identity], :id, nil),
        title: Extension.get_opt(module, [:identity], :title, nil),
        description: Extension.get_opt(module, [:identity], :description, nil),
        authored_ref: Extension.get_opt(module, [:identity], :authored_ref, nil),
        tags: Extension.get_opt(module, [:identity], :tags, [])
      },
      composition: %{
        root: Extension.get_opt(module, [:composition], :root, nil),
        mode: Extension.get_opt(module, [:composition], :mode, :screen),
        summary: Extension.get_opt(module, [:composition], :summary, nil),
        default_slot: Extension.get_opt(module, [:composition], :default_slot, nil)
      },
      default_theme: Extension.get_opt(module, [:themes], :default_theme, nil),
      top_level_nodes: top_level_nodes,
      node_by_id: top_level_nodes |> flatten_nodes() |> Map.new(&{&1.id, &1}),
      authored_themes: authored_themes,
      compiled_themes: [],
      compiled_theme_by_id: %{},
      theme_style_by_id: %{},
      binding_by_id: %{},
      interaction_by_id: %{},
      authored_ids: top_level_nodes |> flatten_nodes() |> Enum.map(& &1.id) |> Enum.sort()
    }
  end

  defp root_metadata(context) do
    Metadata.new(%{
      authored_ref: context.identity.authored_ref,
      description: context.identity.description || context.composition.summary,
      tags: context.identity.tags,
      annotations: %{
        module: context.module,
        identity_id: context.identity.id,
        title: context.identity.title,
        mode: context.composition.mode
      }
    })
  end

  defp root_attributes(context, compiled_bindings, compiled_interactions) do
    %{
      compiled: %{
        module: context.module,
        identity_id: context.identity.id,
        title: context.identity.title,
        mode: context.composition.mode,
        default_slot: context.composition.default_slot,
        summary: context.composition.summary
      }
    }
    |> maybe_put(:theme, root_theme_attachment(context))
    |> maybe_put(:bindings, if(compiled_bindings == [], do: nil, else: compiled_bindings))
    |> maybe_put(
      :interactions,
      if(compiled_interactions == [], do: nil, else: compiled_interactions)
    )
  end

  defp root_theme_attachment(%{default_theme: nil}), do: nil

  defp root_theme_attachment(context) do
    %{
      id: context.default_theme,
      component: context.composition.mode
    }
  end

  defp compile_themes(themes) do
    authored_by_id = Map.new(themes, &{&1.id, &1})

    {compiled_by_id, style_by_id} =
      Enum.reduce(themes, {%{}, %{}}, fn theme, {compiled_by_id, style_by_id} ->
        {compiled_theme, compiled_by_id, style_by_id} =
          compile_theme(theme.id, authored_by_id, compiled_by_id, style_by_id)

        {Map.put(compiled_by_id, theme.id, compiled_theme), style_by_id}
      end)

    %{
      themes: Enum.map(themes, &Map.fetch!(compiled_by_id, &1.id)),
      by_id: compiled_by_id,
      style_by_id: style_by_id
    }
  end

  defp compile_theme(theme_id, authored_by_id, compiled_by_id, style_by_id) do
    case Map.fetch(compiled_by_id, theme_id) do
      {:ok, compiled_theme} ->
        {compiled_theme, compiled_by_id, style_by_id}

      :error ->
        theme = Map.fetch!(authored_by_id, theme_id)

        {base_theme, compiled_by_id, style_by_id} =
          case theme.extends do
            nil ->
              {Theme.new(%{}), compiled_by_id, style_by_id}

            extends_id ->
              compile_theme(extends_id, authored_by_id, compiled_by_id, style_by_id)
          end

        local_palette =
          theme
          |> UnifiedUi.Theme.palette_colors()
          |> Map.new(&{&1.id, &1.color})

        palette = Map.merge(base_theme.palette, local_palette)
        provisional_theme = %{base_theme | palette: palette}

        local_roles =
          theme
          |> UnifiedUi.Theme.semantic_roles()
          |> Map.new(fn role ->
            {role.id, resolve_theme_role_value(role.value, provisional_theme)}
          end)

        roles = Map.merge(base_theme.roles, local_roles)
        role_theme = %{provisional_theme | roles: roles}

        {tokens, token_theme} =
          Enum.reduce(UnifiedUi.Theme.tokens(theme), {base_theme.tokens, role_theme}, fn token,
                                                                                         {tokens,
                                                                                          current_theme} ->
            resolved = resolve_theme_token_value(token.value, current_theme)

            tokens =
              Map.put(
                tokens,
                token_path_key([token.id]),
                UnifiedIUR.Token.define([token.id], resolved)
              )

            {tokens, %{current_theme | tokens: tokens}}
          end)

        {local_components, local_style_by_id} =
          Enum.reduce(
            UnifiedUi.Theme.component_styles(theme),
            {%{}, style_by_id},
            fn component_style, {components, style_by_id} ->
              style = lower_style(component_style.style, token_theme)
              components = merge_component_buckets(components, component_style, style)
              style_by_id = Map.put(style_by_id, component_style.id, style)
              {components, style_by_id}
            end
          )

        compiled_theme =
          Theme.new(%{
            id: theme.id,
            palette: palette,
            roles: roles,
            tokens: tokens,
            defaults: base_theme.defaults,
            components: merge_component_maps(base_theme.components, local_components),
            extra: %{
              authored_ref: theme.authored_ref,
              description: theme.description,
              summary: theme.summary,
              extends: theme.extends,
              inherit?: theme.inherit?
            }
          })

        {compiled_theme, Map.put(compiled_by_id, theme.id, compiled_theme), local_style_by_id}
    end
  end

  defp merge_component_buckets(components, component_style, style) do
    Map.update(
      components,
      component_style.component,
      component_bucket(component_style, style),
      &merge_component_maps(&1, component_bucket(component_style, style))
    )
  end

  defp component_bucket(component_style, style) do
    cond do
      component_style.variant ->
        %{variants: %{component_style.variant => style}}

      component_style.state ->
        %{states: %{component_style.state => style}}

      true ->
        %{default: style}
    end
  end

  defp merge_component_maps(left, right) do
    Map.merge(left, right, fn _component, left_bucket, right_bucket ->
      %{}
      |> maybe_put(:default, Map.get(right_bucket, :default, Map.get(left_bucket, :default)))
      |> maybe_put(
        :variants,
        Map.merge(Map.get(left_bucket, :variants, %{}), Map.get(right_bucket, :variants, %{}))
      )
      |> maybe_put(
        :states,
        Map.merge(Map.get(left_bucket, :states, %{}), Map.get(right_bucket, :states, %{}))
      )
    end)
  end

  defp resolve_theme_role_value(value, compiled_theme) do
    cond do
      UnifiedUi.Style.role_reference?(value) ->
        resolve_role_reference(value, compiled_theme)

      token_reference?(value) ->
        UnifiedIUR.Token.new(value)

      true ->
        UnifiedIUR.Style.Color.new(value)
    end
  end

  defp resolve_theme_token_value(%UnifiedUi.Style{} = style, compiled_theme),
    do: lower_style(style, compiled_theme)

  defp resolve_theme_token_value(style, compiled_theme) when is_map(style) or is_list(style),
    do: lower_style(style, compiled_theme)

  defp resolve_theme_token_value(value, _compiled_theme), do: value

  defp compile_bindings(bindings) do
    Enum.map(bindings, &compile_binding/1)
  end

  defp compile_binding(binding) do
    binding = UnifiedUi.Binding.new(binding)

    IURBinding.new(%{
      name: binding.id,
      path: binding.path,
      scope: binding.scope,
      default: binding.default,
      format: binding.format,
      source: binding.source,
      collection?: binding.collection?,
      depends_on: Enum.map(binding.depends_on, &compiled_binding_ref/1),
      derived: binding.derived,
      metadata: %{
        summary: binding.summary,
        authored_id: binding.id
      }
    })
  end

  defp compile_interactions(interactions, binding_by_id) do
    Enum.map(interactions, &compile_interaction(&1, binding_by_id))
  end

  defp compile_interaction(interaction, binding_by_id) do
    interaction = Signal.new(interaction)
    compiled_target = compile_target_intent(interaction, binding_by_id)

    Interaction.new(%{
      family: interaction.family,
      intent: interaction.intent,
      source: normalize_map(interaction.source_context),
      target: compiled_target,
      payload: compile_payload_map(interaction.payload_mapping, binding_by_id),
      metadata: %{
        summary: interaction.summary,
        authored_id: interaction.id,
        binding_refs:
          Enum.map(interaction.binding_refs, &compile_binding_ref_value(&1, binding_by_id))
      }
    })
  end

  defp compile_target_intent(%Signal{} = interaction, binding_by_id) do
    target_intent = compile_payload_map(interaction.target_intent, binding_by_id)

    case {interaction.family, Signal.navigation_target_kind(interaction)} do
      {:navigation, kind}
      when kind in [
             :screen_transition,
             :replace_transition,
             :history_transition,
             :modal_transition
           ] ->
        %{
          navigation:
            %{}
            |> maybe_put(:kind, kind)
            |> maybe_put(:action, Map.get(target_intent, :action))
            |> maybe_put(:screen, Map.get(target_intent, :screen))
            |> maybe_put(:modal, Map.get(target_intent, :modal))
            |> maybe_put(:params, compact_optional_map(Map.get(target_intent, :params)))
            |> maybe_put(:metadata, compact_optional_map(Map.get(target_intent, :metadata)))
            |> maybe_put(
              :modal_stack,
              compact_optional_map(
                Signal.navigation_modal_stack_semantics()[Map.get(target_intent, :action)]
              )
            )
        }

      _other ->
        target_intent
    end
  end

  defp interaction_identifier(interaction) do
    interaction.metadata[:authored_id] || interaction.intent
  end

  defp lower_node(node, context, visited) do
    if MapSet.member?(visited, node.id) do
      Element.new(:composite, :reference_cycle,
        id: "cycle:#{node.id}",
        metadata:
          Metadata.new(%{
            description: "Reference cycle placeholder for #{inspect(node.id)}",
            annotations: %{ref: node.id}
          })
      )
    else
      visited = MapSet.put(visited, node.id)
      attachments = node_attachments(node, context)

      case node.kind do
        :content ->
          Container.content(
            lower_children(node, context, visited),
            common_opts(node, attachments)
          )

        :box ->
          Container.box(lower_children(node, context, visited), common_opts(node, attachments))

        :row ->
          Layout.row(lower_children(node, context, visited), common_opts(node, attachments))

        :column ->
          Layout.column(lower_children(node, context, visited), common_opts(node, attachments))

        :grid ->
          Layout.grid(
            lower_children(node, context, visited),
            common_opts(node, attachments, [:columns, :rows, :gap, :align, :justify])
          )

        :stack ->
          Layout.stack(
            lower_children(node, context, visited),
            common_opts(node, attachments, [:align])
          )

        :form_builder ->
          Forms.form_builder(
            lower_children(node, context, visited),
            common_opts(node, attachments, [:submit_intent])
          )

        :field_group ->
          Forms.field_group(
            lower_children(node, context, visited),
            common_opts(node, attachments, [:legend])
          )

        :field ->
          lower_field(node, context, visited, attachments)

        :form_field ->
          lower_field(node, context, visited, attachments, :form_field)

        :text ->
          Widgets.Foundational.text(node.value || "", common_opts(node, attachments))

        :label ->
          Widgets.Foundational.label(node.value || "", common_opts(node, attachments, [:target]))

        :icon ->
          Widgets.Foundational.icon(
            node.name,
            common_opts(node, attachments, [:set, :fallback_text])
          )

        :image ->
          Widgets.Foundational.image(
            node.source || "",
            common_opts(node, attachments, [:alt_text, :media_type, :fit])
          )

        :badge ->
          Widgets.Foundational.badge(
            node.value || "",
            common_opts(node, attachments,
              icon: node.name,
              icon_set: node.set,
              presentation: node.presentation
            )
          )

        :hero ->
          Widgets.Foundational.hero(
            lower_children(node, context, visited),
            common_opts(node, attachments,
              eyebrow: node.eyebrow,
              title: node.title,
              message: node.message,
              align: node.align
            )
          )

        :button ->
          Widgets.Foundational.button(node.label || "", common_opts(node, attachments))

        :link ->
          Widgets.Foundational.link(
            node.label || "",
            node.target || "",
            common_opts(node, attachments, [:external?])
          )

        :separator ->
          Widgets.Foundational.separator(
            common_opts(node, attachments, [:orientation, :decorative?])
          )

        :spacer ->
          Widgets.Foundational.spacer(common_opts(node, attachments, [:size, :grow]))

        :text_input ->
          Widgets.Input.text_input(
            common_opts(node, attachments, [:placeholder, :value_path, :default_value])
          )

        :numeric_input ->
          Widgets.Input.numeric_input(
            common_opts(node, attachments, [
              :placeholder,
              :value_path,
              :default_value,
              :min,
              :max,
              :step
            ])
          )

        :toggle ->
          Widgets.Input.toggle(
            common_opts(node, attachments, [:label, :value_path, :default_value])
          )

        :checkbox ->
          Widgets.Input.checkbox(
            common_opts(node, attachments, [:label, :value_path, :default_value])
          )

        :radio_group ->
          Widgets.Input.radio_group(
            normalize_keyword_items(node.options),
            common_opts(node, attachments, [:label, :value_path, :default_value])
          )

        :select ->
          Widgets.Input.select(
            normalize_keyword_items(node.options),
            common_opts(node, attachments, [:label, :value_path, :default_value, :multiple?])
          )

        :pick_list ->
          Widgets.Input.pick_list(
            normalize_keyword_items(node.options),
            common_opts(node, attachments, [:label, :value_path, :default_value, :multiple?])
          )

        :date_input ->
          Widgets.Input.date_input(
            common_opts(node, attachments, [:value_path, :default_value, :format, :min, :max])
          )

        :time_input ->
          Widgets.Input.time_input(
            common_opts(node, attachments, [
              :value_path,
              :default_value,
              :format,
              :min,
              :max,
              :step
            ])
          )

        :file_input ->
          Widgets.Input.file_input(
            common_opts(node, attachments, [:label, :value_path, :accept, :multiple?, :capture])
          )

        :menu ->
          Widgets.Navigation.menu(
            normalize_keyword_items(node.items || node.options),
            common_opts(node, attachments, [:active_item, :orientation])
          )

        :tabs ->
          Widgets.Navigation.tabs(
            normalize_keyword_items(node.items || node.options),
            common_opts(node, attachments, [:active_item, :orientation])
          )

        :command_palette ->
          Widgets.Advanced.command_palette(
            normalize_keyword_items(node.items || node.options),
            common_opts(node, attachments, [:label])
          )

        :list ->
          Widgets.Data.list(
            normalize_list(node.items),
            common_opts(node, attachments, [:ordered?, :selection_mode, :empty_state])
          )

        :table ->
          Widgets.Data.table(
            normalize_table_columns(node.table_columns),
            normalize_table_rows(node.table_rows),
            common_opts(node, attachments, [:empty_state])
          )

        :tree_view ->
          Widgets.Data.tree_view(
            normalize_list(node.tree_nodes),
            common_opts(node, attachments, [:expanded?, :empty_state])
          )

        :stat ->
          Widgets.Data.stat(
            common_opts(node, attachments,
              title: node.title,
              value: node.value,
              message: node.message
            )
          )

        :key_value ->
          Widgets.Data.key_value(
            node.label || "",
            node.value,
            common_opts(node, attachments, description: node.description)
          )

        :info_list ->
          Widgets.Data.info_list(
            normalize_list(node.items),
            common_opts(node, attachments, [:ordered?, :empty_state])
          )

        :markdown_viewer ->
          Widgets.Advanced.markdown_viewer(node.source || "", common_opts(node, attachments))

        :log_viewer ->
          Widgets.Advanced.log_viewer(
            normalize_list(node.log_entries),
            common_opts(node, attachments, [:wrap?, :show_timestamps?])
          )

        :status ->
          Widgets.Feedback.status(
            node.value || "",
            common_opts(node, attachments, severity: node.severity, status: node.status)
          )

        :progress ->
          Widgets.Feedback.progress(
            common_opts(node, attachments,
              current: node.current,
              total: node.maximum,
              label: node.label,
              severity: node.severity,
              status: node.status,
              indeterminate?: node.indeterminate?
            )
          )

        :gauge ->
          Widgets.Feedback.gauge(
            common_opts(node, attachments,
              value: node.current,
              min: node.minimum,
              max: node.maximum,
              label: node.label,
              severity: node.severity,
              status: node.status
            )
          )

        :inline_feedback ->
          Widgets.Feedback.inline_feedback(
            node.message || "",
            common_opts(node, attachments,
              title: node.title,
              severity: node.severity,
              status: node.status
            )
          )

        :sparkline ->
          UnifiedIUR.Canvas.sparkline(
            normalize_number_points(node.points),
            common_opts(node, attachments)
          )

        :bar_chart ->
          UnifiedIUR.Canvas.bar_chart(
            normalize_series(node.series),
            common_opts(node, attachments, x_label: node.x_label, y_label: node.y_label)
          )

        :line_chart ->
          UnifiedIUR.Canvas.line_chart(
            normalize_series(node.series),
            common_opts(node, attachments, x_label: node.x_label, y_label: node.y_label)
          )

        :stream_widget ->
          Widgets.Advanced.stream_widget(
            normalize_list(node.entries),
            common_opts(node, attachments, [:ordering, :severity_field, :timestamp_field])
          )

        :process_monitor ->
          Widgets.Advanced.process_monitor(
            normalize_list(node.processes),
            common_opts(node, attachments, [:sort_by, :severity])
          )

        :cluster_dashboard ->
          Widgets.Advanced.cluster_dashboard(
            normalize_list(node.cluster_nodes),
            common_opts(node, attachments,
              summary: normalize_map(node.metrics),
              severity: node.severity
            )
          )

        :supervision_tree_viewer ->
          Widgets.Advanced.supervision_tree_viewer(
            normalize_list(node.topology),
            common_opts(node, attachments, [:expanded?])
          )

        :dialog ->
          UnifiedIUR.Layer.dialog(
            lower_referenced_node(node.content_ref, context, visited, :dialog),
            common_opts(node, attachments,
              title: node.title,
              modal?: node.modal?
            )
          )

        :alert_dialog ->
          UnifiedIUR.Layer.alert_dialog(
            overlay_message_content(node.id, node.message || ""),
            common_opts(node, attachments,
              title: node.title,
              severity: node.severity
            )
          )

        :toast ->
          UnifiedIUR.Layer.toast(
            overlay_notice_content(node.id, node.title, node.message || ""),
            common_opts(node, attachments,
              placement: node.placement,
              severity: node.severity
            )
          )

        :context_menu ->
          UnifiedIUR.Layer.context_menu(
            normalize_keyword_items(node.options),
            common_opts(node, attachments,
              anchor: %{target_id: node.target_ref},
              placement: node.placement
            )
          )

        :overlay ->
          UnifiedIUR.Layer.overlay(
            lower_referenced_node(node.base_ref, context, visited, :overlay_base),
            Enum.map(List.wrap(node.layer_refs), fn ref ->
              lower_referenced_node(ref, context, visited, :overlay_layer)
            end),
            common_opts(node, attachments, background_fill: node.background_fill)
          )

        :absolute ->
          generic_element(:layer, :absolute, node, attachments, %{
            absolute: %{
              content_ref: node.content_ref,
              target_ref: node.target_ref,
              x: node.x,
              y: node.y,
              z_index: node.z_index
            }
          })

        :viewport ->
          lower_viewport(node, context, visited, attachments)

        :scroll_region ->
          generic_element(:layout, :scroll_region, node, attachments, %{
            scroll_region: %{
              content_ref: node.content_ref,
              height: node.height,
              offset: node.offset,
              clip?: node.clip?
            }
          })

        :scroll_bar ->
          UnifiedIUR.Viewport.scroll_bar(
            common_opts(node, attachments,
              viewport_ref: node.target_ref,
              position: node.position,
              viewport_size: node.viewport_size,
              content_size: node.content_size,
              orientation: node.orientation
            )
          )

        :split_pane ->
          lower_split_pane(node, context, visited, attachments)

        :canvas ->
          UnifiedIUR.Canvas.surface(
            normalize_list(node.operations),
            common_opts(node, attachments, [:width, :height])
          )

        :inline_rich_text_heading ->
          Widgets.Components.inline_rich_text_heading(
            node.level || :h1,
            normalize_list(node.segments),
            common_opts(node, attachments)
          )

        :disclosure ->
          Widgets.Components.disclosure(
            node.summary || "",
            lower_children(node, context, visited),
            common_opts(node, attachments, [:open?])
          )

        :kicker ->
          Widgets.Components.kicker(
            List.wrap(node.items),
            common_opts(node, attachments, [:separator])
          )

        :avatar ->
          Widgets.Components.avatar(
            common_opts(node, attachments, [
              :initials,
              :image_source,
              :size,
              :shape,
              :accessibility_label,
              :accessibility_description
            ])
          )

        :presence_dot ->
          Widgets.Components.presence_dot(
            node.state || :quiet,
            common_opts(node, attachments, [:size, :accessibility_label])
          )

        :unread_badge ->
          Widgets.Components.unread_badge(
            node.count || 0,
            common_opts(node, attachments, %{tone: node.tone})
          )

        :segmented_button_group ->
          Widgets.Components.segmented_button_group(
            normalize_keyword_items(node.options),
            common_opts(node, attachments, [:active_value, :selection_intent, :disabled?])
          )

        :runtime_form_shell ->
          Widgets.Components.runtime_form_shell(
            normalize_list(node.fields),
            common_opts(node, attachments,
              submit_label: node.submit_label,
              submit_intent: node.submit_intent,
              change_intent: node.change_intent,
              validation_state: node.validation_state,
              host_adapter_hints: normalize_annotation_hints(node.annotations)
            )
          )

        :chat_composer ->
          Widgets.Components.chat_composer(
            lower_children(node, context, visited),
            common_opts(node, attachments, [
              :name,
              :value,
              :placeholder,
              :rows,
              :send_label,
              :send_intent,
              :change_intent,
              :disabled?
            ])
          )

        :list_item_multi_column ->
          Widgets.Components.list_item_multi_column(
            lower_children(node, context, visited),
            common_opts(node, attachments, [
              :row_identity,
              :column_template,
              :active?,
              :link_target,
              :action_intent
            ])
          )

        :artifact_row ->
          Widgets.Components.artifact_row(
            node.title || "",
            lower_children(node, context, visited),
            common_opts(node, attachments, [
              :row_identity,
              :active?,
              :link_target,
              :action_intent,
              :meta
            ])
          )

        :pipeline_stepper_horizontal ->
          Widgets.Components.pipeline_stepper_horizontal(
            normalize_list(node.steps),
            common_opts(node, attachments, [
              :active_index,
              :completed_indices,
              :navigation_intent
            ])
          )

        :segmented_progress_bar ->
          Widgets.Components.segmented_progress_bar(
            normalize_list(node.segments),
            common_opts(node, attachments, [:aggregate_progress, :label])
          )

        :workflow_stage_list_vertical ->
          Widgets.Components.workflow_stage_list_vertical(
            normalize_list(node.stages),
            common_opts(node, attachments, [:active_index])
          )

        :meter_thin ->
          Widgets.Components.meter_thin(
            node.current || 0,
            common_opts(node, attachments, [:minimum, :maximum, :label, :state])
          )

        :sticky_frosted_header ->
          Widgets.Components.sticky_frosted_header(
            lower_children(node, context, visited),
            common_opts(node, attachments, [:title, :leading, :trailing])
          )

        :slide_over_panel ->
          Widgets.Components.slide_over_panel(
            lower_children(node, context, visited),
            common_opts(node, attachments, [
              :open?,
              :size,
              :dismiss_intent,
              :accessibility_label,
              :accessibility_description
            ])
          )

        :event_callout ->
          Widgets.Components.event_callout(
            node.message || "",
            lower_children(node, context, visited),
            common_opts(node, attachments, [
              :tone,
              :eyebrow,
              :title,
              :action_intent
            ])
          )

        :redline_inline ->
          Widgets.Components.redline_inline(
            normalize_list(node.segments),
            common_opts(node, attachments, [:text_safety])
          )

        :code_block_syntax_highlighted ->
          Widgets.Components.code_block_syntax_highlighted(
            node.language || :plain_text,
            normalize_list(node.tokens),
            common_opts(node, attachments, [:text_safety])
          )

        :list_repeat ->
          lower_list_repeat(node, context, visited, attachments)

        other ->
          generic_element(element_type(node.family), other, node, attachments, %{
            authored: %{
              family: node.family,
              summary: node.summary
            }
          })
      end
    end
  end

  defp lower_field(node, context, visited, attachments, constructor \\ :field) do
    control =
      case node.children do
        [child | _rest] -> lower_node(child, context, visited)
        [] -> Element.new(:widget, :empty_field_control, id: "#{node.id}-control")
      end

    apply(Forms, constructor, [
      control,
      common_opts(node, attachments,
        name: node.field_name,
        label: node.label,
        help: node.help,
        path: node.value_path,
        default: node.default_value
      )
    ])
  end

  defp lower_children(node, context, visited) do
    Enum.map(node.children, fn child ->
      Element.Child.new(:default, lower_node(child, context, visited))
    end)
  end

  defp lower_viewport(node, context, visited, attachments) do
    UnifiedIUR.Viewport.region(
      lower_referenced_node(node.content_ref, context, visited, :viewport),
      common_opts(node, attachments,
        width: node.width,
        height: node.height,
        offset: node.offset,
        clip?: node.clip?
      )
    )
  end

  defp lower_split_pane(node, context, visited, attachments) do
    UnifiedIUR.Viewport.split_pane(
      lower_referenced_node(node.primary_ref, context, visited, :split_primary),
      lower_referenced_node(node.secondary_ref, context, visited, :split_secondary),
      common_opts(node, attachments,
        direction: node.orientation,
        ratio: node.ratio,
        divider_size: node.divider_size,
        divider_style: node.divider_style
      )
    )
  end

  defp lower_list_repeat(node, context, visited, attachments) do
    template_node = List.first(node.children)
    template = if(template_node, do: lower_node(template_node, context, visited))
    binding = Map.get(context.binding_by_id, node.repeat_binding)
    rows = repeat_rows(binding)

    hydrated_children =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, index} ->
        Element.Child.new(:default, hydrate_repeat_template(template, node, row, index))
      end)

    opts =
      node
      |> common_opts(attachments,
        repeat_binding: node.repeat_binding,
        binding_ref: compile_binding_ref_value(node.repeat_binding, context.binding_by_id),
        row_scope: node.row_scope,
        row_fields: node.row_fields || [],
        template_identity: node.template_identity || template_identity(template),
        identity_strategy: node.identity_strategy,
        hydrated?: true,
        row_count: length(rows),
        template: template_summary(template)
      )
      |> Map.put(:children, hydrated_children)

    Widgets.Components.list_repeat(template, opts)
  end

  defp repeat_rows(%IURBinding{default: rows}) when is_list(rows) do
    Enum.map(rows, &normalize_repeat_row/1)
  end

  defp repeat_rows(_binding), do: []

  defp normalize_repeat_row(row) when is_map(row), do: normalize_keyword_tree(row)

  defp normalize_repeat_row(row) when is_list(row) do
    if Keyword.keyword?(row), do: normalize_keyword_tree(row), else: %{value: row}
  end

  defp normalize_repeat_row(row), do: %{value: row}

  defp hydrate_repeat_template(nil, _repeat_node, _row, _index), do: nil

  defp hydrate_repeat_template(template, repeat_node, row, index) do
    identity = repeat_identity_value(repeat_node, template, row, index)
    hydrate_repeat_element(template, repeat_node, row, index, identity, [])
  end

  defp hydrate_repeat_element(nil, _repeat_node, _row, _index, _identity, _path), do: nil

  defp hydrate_repeat_element(element, repeat_node, row, index, identity, path) do
    id = repeat_instance_id(repeat_node, identity, element.id, path)

    children =
      element.children
      |> Enum.with_index()
      |> Enum.map(fn {child, child_index} ->
        %{
          child
          | element:
              hydrate_repeat_element(
                child.element,
                repeat_node,
                row,
                index,
                identity,
                path ++ [child_index]
              )
        }
      end)

    %{
      element
      | id: id,
        attributes:
          element.attributes
          |> project_repeat_attributes(row, repeat_node)
          |> put_repeat_instance_metadata(repeat_node, row, index)
          |> retarget_interactions(id, row, repeat_node),
        children: children
    }
  end

  defp repeat_instance_id(repeat_node, identity, nil, path) do
    path_id =
      path
      |> Enum.map_join("_", &to_string/1)
      |> case do
        "" -> "item"
        value -> value
      end

    repeat_instance_id(repeat_node, identity, path_id, [])
  end

  defp repeat_instance_id(repeat_node, identity, original_id, _path) do
    Enum.map_join([repeat_node.id, identity, original_id], ":", &to_string/1)
  end

  defp repeat_identity_value(%Node{identity_strategy: :index}, _template, _row, index), do: index

  defp repeat_identity_value(%Node{identity_strategy: :stable_hash}, _template, row, _index) do
    :erlang.phash2(row)
  end

  defp repeat_identity_value(_repeat_node, template, row, index) do
    case template_row_identity(template) do
      nil -> row_value(row, :id) || index
      field when is_atom(field) or is_binary(field) -> row_value(row, field) || field
      value -> value
    end
  end

  defp template_identity(nil), do: nil
  defp template_identity(%Element{id: id}), do: id

  defp template_summary(nil), do: nil

  defp template_summary(%Element{} = template) do
    %{
      id: template.id,
      type: template.type,
      kind: template.kind
    }
  end

  defp template_row_identity(nil), do: nil

  defp template_row_identity(%Element{attributes: attributes}) do
    get_in(attributes, [:row, :row_identity]) ||
      get_in(attributes, [:artifact, :row_identity])
  end

  defp project_repeat_attributes(attributes, row, repeat_node) do
    attributes
    |> project_repeat_group(:row, row, repeat_node)
    |> project_repeat_group(:artifact, row, repeat_node)
    |> project_repeat_group(:callout, row, repeat_node)
  end

  defp project_repeat_group(attributes, group, row, repeat_node) do
    case Map.fetch(attributes, group) do
      {:ok, value} -> Map.put(attributes, group, project_repeat_value(value, row, repeat_node))
      :error -> attributes
    end
  end

  defp project_repeat_value(value, row, repeat_node) when is_map(value) do
    Map.new(value, fn {key, nested} ->
      {key, project_repeat_value(nested, row, repeat_node)}
    end)
  end

  defp project_repeat_value(value, row, repeat_node) when is_list(value) do
    Enum.map(value, &project_repeat_value(&1, row, repeat_node))
  end

  defp project_repeat_value(value, row, repeat_node) when is_atom(value) or is_binary(value) do
    if repeat_field?(repeat_node, value) do
      row_value(row, value) || value
    else
      value
    end
  end

  defp project_repeat_value(value, _row, _repeat_node), do: value

  defp put_repeat_instance_metadata(attributes, repeat_node, row, index) do
    Map.put(attributes, :repeat_instance, %{
      source_repeat_id: repeat_node.id,
      row_scope: repeat_node.row_scope || :row,
      row_index: index,
      values: select_repeat_values(row, repeat_node.row_fields || [])
    })
  end

  defp retarget_interactions(attributes, id, row, repeat_node) do
    case Map.fetch(attributes, :interactions) do
      {:ok, interactions} ->
        Map.put(
          attributes,
          :interactions,
          Enum.map(interactions, &retarget_interaction(&1, id, row, repeat_node))
        )

      :error ->
        attributes
    end
  end

  defp retarget_interaction(%Interaction{} = interaction, id, row, repeat_node) do
    %{
      interaction
      | source: Map.put(interaction.source, :element_id, id),
        payload: project_repeat_value(interaction.payload, row, repeat_node)
    }
  end

  defp retarget_interaction(interaction, _id, _row, _repeat_node), do: interaction

  defp repeat_field?(%Node{row_fields: row_fields}, field) do
    Enum.any?(List.wrap(row_fields), &(to_string(&1) == to_string(field)))
  end

  defp select_repeat_values(row, row_fields) do
    row_fields
    |> List.wrap()
    |> Enum.reduce(%{}, fn field, acc ->
      case row_value(row, field) do
        nil -> acc
        value -> Map.put(acc, field, value)
      end
    end)
  end

  defp row_value(row, field) when is_atom(field) do
    Map.get(row, field, Map.get(row, Atom.to_string(field)))
  end

  defp row_value(row, field) when is_binary(field) do
    Map.get(row, field)
  end

  defp overlay_message_content(node_id, message) do
    Widgets.Foundational.text(message, id: "#{node_id}_content")
  end

  defp overlay_notice_content(node_id, nil, message) do
    overlay_message_content(node_id, message)
  end

  defp overlay_notice_content(node_id, title, message) do
    Container.box(
      [
        Element.Child.new(
          :default,
          Widgets.Foundational.text(title, id: "#{node_id}_title")
        ),
        Element.Child.new(
          :default,
          Widgets.Foundational.text(message, id: "#{node_id}_message")
        )
      ],
      id: "#{node_id}_content"
    )
  end

  defp lower_referenced_node(ref, context, visited, kind) do
    case Map.get(context.node_by_id, ref) do
      nil ->
        Element.new(:composite, :missing_reference,
          id: "missing:#{kind}:#{ref}",
          metadata:
            Metadata.new(%{
              description: "Missing authored reference #{inspect(ref)}",
              annotations: %{ref: ref, kind: kind}
            })
        )

      referenced ->
        lower_node(referenced, context, visited)
    end
  end

  defp node_attachments(node, context) do
    bindings = compile_node_bindings(node, context)
    interactions = compile_node_interactions(node, context)
    compiled_theme = compiled_theme(node, context)

    %{
      style: resolved_node_style(node, compiled_theme, context),
      theme: compile_theme_attachment(node, context),
      bindings: if(bindings == [], do: nil, else: bindings),
      interactions: if(interactions == [], do: nil, else: interactions)
    }
  end

  defp compile_node_bindings(node, context) do
    explicit =
      node.binding_refs
      |> List.wrap()
      |> Enum.map(&Map.get(context.binding_by_id, &1))
      |> Enum.reject(&is_nil/1)

    fallback =
      case {node.value_path, node.field_name || node.id} do
        {nil, _name} ->
          []

        {path, name} ->
          [
            IURBinding.new(%{
              name: name,
              path: List.wrap(path),
              default: node.default_value,
              metadata: %{source: :authored_node}
            })
          ]
      end

    explicit ++ fallback
  end

  defp compile_node_interactions(node, context) do
    explicit =
      node.interaction_refs
      |> List.wrap()
      |> Enum.map(&Map.get(context.interaction_by_id, &1))
      |> Enum.reject(&is_nil/1)

    fallback =
      [
        default_action_interaction(node),
        default_submit_interaction(node),
        default_change_interaction(node),
        default_selection_interaction(node),
        default_step_navigation_interaction(node),
        default_send_interaction(node),
        default_dismiss_interaction(node)
      ]
      |> Enum.reject(&is_nil/1)

    explicit ++ fallback
  end

  defp default_action_interaction(%Node{action_intent: nil}), do: nil

  defp default_action_interaction(node) do
    Interaction.click(
      intent: node.action_intent,
      element_id: node.id,
      value: node.row_identity,
      mapping: default_action_mapping(node),
      phase: :authored_default
    )
  end

  defp default_submit_interaction(%Node{submit_intent: nil}), do: nil

  defp default_submit_interaction(node) do
    Interaction.submit(
      intent: node.submit_intent,
      element_id: node.id,
      mapping: default_submit_mapping(node),
      phase: :authored_default
    )
  end

  defp default_change_interaction(%Node{change_intent: nil}), do: nil

  defp default_change_interaction(node) do
    Interaction.change(
      intent: node.change_intent,
      element_id: node.id,
      mapping: default_change_mapping(node),
      phase: :authored_default
    )
  end

  defp default_selection_interaction(%Node{selection_intent: nil}), do: nil

  defp default_selection_interaction(node) do
    Interaction.selection(
      intent: node.selection_intent,
      element_id: node.id,
      selection: node.active_value,
      mapping: %{selected_value: :value},
      phase: :authored_default
    )
  end

  defp default_step_navigation_interaction(%Node{navigation_intent: nil}), do: nil

  defp default_step_navigation_interaction(node) do
    Interaction.navigation(
      intent: node.navigation_intent,
      element_id: node.id,
      mapping: %{step_id: :id, step_index: :index},
      phase: :authored_default
    )
  end

  defp default_send_interaction(%Node{send_intent: nil}), do: nil

  defp default_send_interaction(node) do
    Interaction.submit(
      intent: node.send_intent,
      element_id: node.id,
      mapping: %{message: :value},
      phase: :authored_default
    )
  end

  defp default_dismiss_interaction(%Node{dismiss_intent: nil}), do: nil

  defp default_dismiss_interaction(node) do
    Interaction.close(
      intent: node.dismiss_intent,
      element_id: node.id,
      mapping: %{open?: false},
      phase: :authored_default
    )
  end

  defp default_action_mapping(%Node{row_identity: nil}), do: nil
  defp default_action_mapping(%Node{kind: kind}) when kind in [:event_callout, :button], do: nil
  defp default_action_mapping(_node), do: %{row_identity: :row_identity}

  defp default_submit_mapping(%Node{kind: :runtime_form_shell}), do: %{fields: :field_values}
  defp default_submit_mapping(_node), do: nil

  defp default_change_mapping(%Node{kind: :runtime_form_shell}), do: %{fields: :field_values}
  defp default_change_mapping(%Node{kind: :chat_composer}), do: %{message: :value}
  defp default_change_mapping(_node), do: %{value: :value}

  defp compile_theme_attachment(node, context) do
    theme_id = node.theme_ref || context.default_theme

    if is_nil(theme_id) do
      nil
    else
      %{
        id: theme_id,
        component: node.kind,
        variant: node.variant,
        style_refs: node.style_refs
      }
    end
  end

  defp compiled_theme(node, context) do
    theme_id = node.theme_ref || context.default_theme
    Map.get(context.compiled_theme_by_id, theme_id)
  end

  defp resolved_node_style(node, compiled_theme, context) do
    base_style =
      case compiled_theme do
        nil -> %Style{}
        theme -> Theme.resolve_style(theme, node.kind, variant: node.variant)
      end

    style_ref_style =
      node.style_refs
      |> List.wrap()
      |> Enum.map(&Map.get(context.theme_style_by_id, &1))
      |> Enum.reject(&is_nil/1)
      |> Enum.reduce(%Style{}, &Style.merge(&2, &1))

    local_style = lower_style(node.style, compiled_theme)

    resolved =
      base_style
      |> Style.merge(style_ref_style)
      |> Style.merge(local_style)

    if resolved == %Style{}, do: nil, else: resolved
  end

  defp common_opts(node, attachments, extra \\ []) do
    extra =
      cond do
        Keyword.keyword?(extra) -> Enum.into(extra, %{})
        is_list(extra) -> Enum.into(extra, %{}, fn key -> {key, Map.get(node, key)} end)
        is_map(extra) -> Map.new(extra)
        true -> %{}
      end

    %{
      id: node.id,
      description: node.summary || node.description,
      authored_ref: node.authored_ref,
      annotations: node.annotations,
      tags: node.tags,
      style: attachments.style,
      theme: attachments.theme,
      bindings: attachments.bindings,
      interactions: attachments.interactions
    }
    |> Map.merge(extra)
    |> Enum.reject(fn {_key, value} -> value in [nil, []] end)
    |> Map.new()
  end

  defp generic_element(type, kind, node, attachments, attribute_groups) do
    Element.new(type, kind,
      id: node.id,
      metadata:
        Metadata.new(%{
          authored_ref: node.authored_ref,
          description: node.summary || node.description,
          tags: node.tags,
          annotations: %{
            source_family: node.family
          }
        }),
      attributes:
        attribute_groups
        |> Enum.reject(fn {_key, value} -> value in [%{}, nil] end)
        |> Map.new(fn {key, value} -> {key, compact_map(value)} end)
        |> maybe_put(:style, attachments.style)
        |> maybe_put(:theme, attachments.theme)
        |> maybe_put(:bindings, attachments.bindings)
        |> maybe_put(:interactions, attachments.interactions),
      children: []
    )
  end

  defp lower_style(nil, _compiled_theme), do: nil

  defp lower_style(style, compiled_theme) do
    style = UnifiedUi.Style.new(style)
    {text_attributes, typography_extra} = lower_text_attributes(style.typography)

    token_style = resolve_style_token_refs(style.token_refs, compiled_theme)

    lowered =
      Style.new(%{
        foreground: resolve_color(style.foreground, compiled_theme),
        background: resolve_color(style.background, compiled_theme),
        border_color: resolve_color(style.border_color, compiled_theme),
        text: text_attributes,
        spacing: style.spacing,
        sizing: style.sizing,
        alignment: style.alignment,
        visibility: style.visibility,
        border: style.border,
        emphasis: style.emphasis,
        state_variants:
          Map.new(style.state_variants, fn {key, variant} ->
            {key, lower_style(variant, compiled_theme)}
          end),
        extra:
          %{}
          |> maybe_put(:typography, typography_extra)
          |> maybe_put(:variant, style.variant)
          |> maybe_put(:tone, style.tone)
          |> maybe_put(:component, style.component)
      })
      |> Style.merge(token_style)

    if lowered == %Style{}, do: nil, else: lowered
  end

  defp resolve_color(nil, _compiled_theme), do: nil

  defp resolve_color(value, compiled_theme) do
    cond do
      UnifiedUi.Style.role_reference?(value) ->
        resolve_role_reference(value, compiled_theme)

      token_reference?(value) ->
        resolve_token_color(value, compiled_theme)

      true ->
        UnifiedIUR.Style.Color.new(value)
    end
  end

  defp resolve_style_token_refs(_token_refs, nil), do: %Style{}

  defp resolve_style_token_refs(token_refs, compiled_theme) do
    token_refs
    |> List.wrap()
    |> Enum.reduce(%Style{}, fn token_ref, acc ->
      case resolve_token_style(token_ref, compiled_theme) do
        nil -> acc
        style -> Style.merge(acc, style)
      end
    end)
  end

  defp resolve_role_reference(_value, nil), do: nil

  defp resolve_role_reference(value, compiled_theme) do
    role_id = Map.get(value, :id, Map.get(value, "id"))

    case Map.get(compiled_theme.roles, role_id) do
      %{kind: :token_ref} = token_ref -> resolve_token_color(token_ref, compiled_theme)
      %{"kind" => :token_ref} = token_ref -> resolve_token_color(token_ref, compiled_theme)
      other -> UnifiedIUR.Style.Color.new(other)
    end
  end

  defp resolve_token_color(_value, nil), do: nil

  defp resolve_token_color(value, compiled_theme) do
    token_ref = UnifiedIUR.Token.new(value)
    palette_key = token_ref.path |> List.last()

    cond do
      Map.has_key?(compiled_theme.palette, palette_key) ->
        Map.get(compiled_theme.palette, palette_key)

      true ->
        case Theme.token(compiled_theme, token_ref.path) do
          nil -> nil
          %Style{} -> nil
          other -> UnifiedIUR.Style.Color.new(other)
        end
    end
  end

  defp resolve_token_style(_value, nil), do: nil

  defp resolve_token_style(value, compiled_theme) do
    token_ref = UnifiedIUR.Token.new(value)

    case Theme.token(compiled_theme, token_ref.path) do
      %Style{} = style -> style
      style when is_map(style) or is_list(style) -> Style.new(style)
      _other -> nil
    end
  end

  defp lower_text_attributes(typography) when typography in [nil, %{}] do
    {%{}, nil}
  end

  defp lower_text_attributes(typography) do
    typography = Map.new(typography)

    text_attributes =
      %{}
      |> maybe_put(:bold?, bold_weight?(Map.get(typography, :font_weight)))
      |> maybe_put(:italic?, truthy_attr?(typography, :italic?))
      |> maybe_put(:underline?, truthy_attr?(typography, :underline?))
      |> maybe_put(:blink?, truthy_attr?(typography, :blink?))
      |> maybe_put(:reverse?, truthy_attr?(typography, :reverse?))
      |> maybe_put(:hidden?, truthy_attr?(typography, :hidden?))
      |> maybe_put(:strikethrough?, truthy_attr?(typography, :strikethrough?))

    typography_extra =
      typography
      |> Map.drop([
        :font_weight,
        :italic?,
        :underline?,
        :blink?,
        :reverse?,
        :hidden?,
        :strikethrough?
      ])
      |> compact_map()

    {text_attributes, if(typography_extra == %{}, do: nil, else: typography_extra)}
  end

  defp truthy_attr?(map, key), do: Map.get(map, key) == true

  defp bold_weight?(value) do
    value in [:bold, :semibold, :heavy, :black, "bold", "semibold", "heavy", "black"] or
      (is_integer(value) and value >= 600)
  end

  defp compile_payload_map(values, binding_by_id) when is_map(values) do
    Map.new(values, fn {key, value} ->
      {key, compile_named_payload_value(key, value, binding_by_id)}
    end)
  end

  defp compile_payload_map(values, _binding_by_id) when values in [nil, []], do: %{}

  defp compile_payload_map(values, binding_by_id) when is_list(values) do
    values
    |> Enum.into(%{})
    |> compile_payload_map(binding_by_id)
  end

  defp compile_payload_value(value, binding_by_id) when is_map(value) do
    cond do
      UnifiedUi.Binding.reference?(value) ->
        compile_binding_ref_value(value, binding_by_id)

      true ->
        Map.new(value, fn {key, nested} -> {key, compile_payload_value(nested, binding_by_id)} end)
    end
  end

  defp compile_payload_value(value, binding_by_id) when is_list(value) do
    if Keyword.keyword?(value) do
      value
      |> Enum.into(%{})
      |> compile_payload_value(binding_by_id)
    else
      Enum.map(value, &compile_payload_value(&1, binding_by_id))
    end
  end

  defp compile_payload_value(value, _binding_by_id), do: value

  defp compile_named_payload_value(key, value, binding_by_id)
       when key in [:binding, "binding"] and (is_atom(value) or is_binary(value)) do
    case Map.get(binding_by_id, value) do
      nil -> value
      _binding -> compile_binding_ref_value(value, binding_by_id)
    end
  end

  defp compile_named_payload_value(_key, value, binding_by_id) do
    compile_payload_value(value, binding_by_id)
  end

  defp compile_binding_ref_value(ref, binding_by_id) do
    ref = UnifiedUi.Binding.new(%{depends_on: [ref]}).depends_on |> List.first()

    case Map.get(binding_by_id, ref.id) do
      nil ->
        %{kind: :binding_ref, id: ref.id}

      binding ->
        %{
          kind: :binding_ref,
          id: ref.id,
          name: binding.name,
          path: binding.path,
          scope: binding.scope
        }
    end
  end

  defp compiled_binding_ref(ref) do
    ref = UnifiedUi.Binding.new(%{depends_on: [ref]}).depends_on |> List.first()
    IURBinding.reference([ref.id])
  end

  defp normalize_keyword_items(items) when is_list(items) do
    Enum.map(items, fn
      {id, label} ->
        %{id: id, label: label, value: id}

      %{} = item ->
        normalize_map(item)
    end)
  end

  defp normalize_table_columns(columns) when is_list(columns) do
    Enum.map(columns, fn
      {id, label} -> %{id: id, label: label}
      %{} = column -> normalize_map(column)
    end)
  end

  defp normalize_table_rows(rows) when is_list(rows) do
    Enum.with_index(rows, fn row, index ->
      row = normalize_map(row)

      %{
        id: Map.get(row, :id, Map.get(row, "id", "row-#{index}")),
        cells:
          row
          |> Enum.reject(fn {key, _value} -> key in [:id, "id"] end)
          |> Enum.map(fn {_key, value} -> value end)
      }
    end)
  end

  defp normalize_series(series) when is_list(series) do
    Enum.map(series, &normalize_map/1)
  end

  defp normalize_annotation_hints(value) when value in [nil, []], do: nil

  defp normalize_annotation_hints(value) do
    value
    |> normalize_keyword_tree()
    |> compact_optional_map()
  end

  defp normalize_keyword_tree(value) when is_map(value) do
    Map.new(value, fn {key, nested} -> {key, normalize_keyword_tree(nested)} end)
  end

  defp normalize_keyword_tree(value) when is_list(value) do
    if Keyword.keyword?(value) do
      Map.new(value, fn {key, nested} -> {key, normalize_keyword_tree(nested)} end)
    else
      Enum.map(value, &normalize_keyword_tree/1)
    end
  end

  defp normalize_keyword_tree(value), do: value

  defp normalize_number_points(points) when is_list(points), do: points
  defp normalize_number_points(_other), do: []

  defp normalize_list(nil), do: []
  defp normalize_list(list) when is_list(list), do: Enum.map(list, &normalize_map/1)

  defp element_type(:layout), do: :layout
  defp element_type(:forms), do: :composite
  defp element_type(:overlay), do: :layer
  defp element_type(:display), do: :layout
  defp element_type(:canvas), do: :widget
  defp element_type(_family), do: :widget

  defp flatten_nodes(nodes) when is_list(nodes) do
    Enum.flat_map(nodes, fn %Node{children: children} = node ->
      [node | flatten_nodes(children)]
    end)
  end

  defp token_reference?(%{kind: :token_ref, path: path}) when is_list(path), do: true
  defp token_reference?(%{"kind" => :token_ref, "path" => path}) when is_list(path), do: true
  defp token_reference?(_other), do: false

  defp token_path_key(path), do: Enum.join(Enum.map(path, &to_string/1), ".")

  defp normalize_map(nil), do: %{}
  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(list) when is_list(list), do: Enum.into(list, %{})

  defp compact_map(map) when is_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> value in [nil, [], %{}] end)
    |> Map.new()
  end

  defp compact_optional_map(nil), do: nil
  defp compact_optional_map(map), do: compact_map(map)

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
