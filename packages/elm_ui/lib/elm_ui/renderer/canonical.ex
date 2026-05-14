defmodule ElmUi.Renderer.Canonical do
  @moduledoc """
  Deterministic canonical-to-native widget mapping for the `elm_ui` scaffold.
  """

  alias UnifiedIUR.Element
  alias UnifiedIUR.Element.Child
  alias ElmUi.Renderer.Error
  alias ElmUi.Widgets

  @spec render(Element.t(), keyword()) :: {:ok, ElmUi.Widget.t()} | {:error, Error.t()}
  def render(%Element{} = element, _opts \\ []) do
    do_render(element)
  end

  defp do_render(%Element{id: nil} = element), do: {:error, Error.missing_identity(element)}

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:badge, "badge"] do
    {:ok,
     Widgets.badge(
       element.id,
       first_present(
         [group_attr(element, :content, :text), content_text(element), attr(element, :text)],
         ""
       ),
       Keyword.merge(base_opts(element),
         icon: first_present([group_attr(element, :badge, :icon), attr(element, :icon)]),
         icon_set:
           first_present([group_attr(element, :badge, :icon_set), attr(element, :icon_set)]),
         presentation:
           first_present(
             [group_attr(element, :badge, :presentation), attr(element, :presentation)],
             :pill
           )
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:hero, "hero"] do
    with {:ok, children} <- map_children(default_children(element)),
         {:ok, supporting} <- optional_slot_children(element, :supporting),
         {:ok, actions} <- optional_slot_children(element, :actions) do
      {:ok,
       Widgets.hero(
         element.id,
         children,
         Keyword.merge(base_opts(element),
           eyebrow: first_present([group_attr(element, :hero, :eyebrow), attr(element, :eyebrow)]),
           title: first_present([group_attr(element, :hero, :title), attr(element, :title)]),
           message:
             first_present([group_attr(element, :hero, :message), attr(element, :message)]),
           align: first_present([group_attr(element, :hero, :align), attr(element, :align)]),
           supporting: supporting,
           actions: actions
         )
       )}
    end
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:text, "text"] do
    {:ok,
     Widgets.text(element.id, content_text(element, inspect(element.id)), base_opts(element))}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:label, "label"] do
    {:ok,
     Widgets.label(
       element.id,
       content_text(element, inspect(element.id)),
       Keyword.merge(base_opts(element),
         for: first_present([group_attr(element, :label, :for), attr(element, :for)]),
         relationship:
           first_present(
             [group_attr(element, :label, :relationship), attr(element, :relationship)],
             :label
           )
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:icon, "icon"] do
    {:ok,
     Widgets.icon(
       element.id,
       first_present(
         [group_attr(element, :icon, :name), attr(element, :name), attr(element, :icon)],
         :unknown
       ),
       Keyword.merge(base_opts(element),
         set: first_present([group_attr(element, :icon, :set), attr(element, :set)]),
         fallback_text:
           first_present([
             group_attr(element, :icon, :fallback_text),
             attr(element, :fallback_text)
           ])
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:image, "image"] do
    {:ok,
     Widgets.image(
       element.id,
       first_present(
         [group_attr(element, :image, :source), attr(element, :src), attr(element, :source)],
         ""
       ),
       Keyword.merge(base_opts(element),
         alt: first_present([group_attr(element, :image, :alt_text), attr(element, :alt)], ""),
         fit: first_present([group_attr(element, :image, :fit), attr(element, :fit)], :cover)
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:button, "button"] do
    {:ok,
     Widgets.button(
       element.id,
       first_present([attr(element, :label), content_text(element)], "Button"),
       base_opts(element)
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:link, "link"] do
    {:ok,
     Widgets.link(
       element.id,
       first_present([attr(element, :label), content_text(element)], "Link"),
       first_present([group_attr(element, :link, :target), attr(element, :href)], "#"),
       Keyword.merge(base_opts(element),
         external:
           first_present(
             [group_attr(element, :link, :external?), attr(element, :external)],
             false
           )
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:separator, "separator"] do
    {:ok,
     Widgets.separator(
       element.id,
       Keyword.merge(base_opts(element),
         orientation:
           first_present(
             [group_attr(element, :separator, :orientation), attr(element, :orientation)],
             :horizontal
           ),
         decorative:
           first_present(
             [group_attr(element, :separator, :decorative?), attr(element, :decorative)],
             true
           )
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:spacer, "spacer"] do
    {:ok,
     Widgets.spacer(
       element.id,
       Keyword.merge(base_opts(element),
         size: first_present([group_attr(element, :spacer, :size), attr(element, :size)], :md),
         grow: first_present([group_attr(element, :spacer, :grow), attr(element, :grow)], 0)
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:content, "content"] do
    with {:ok, children} <- map_children(default_children(element)) do
      {:ok,
       Widgets.content(
         element.id,
         children,
         Keyword.merge(base_opts(element),
           role:
             first_present(
               [group_attr(element, :container, :role), attr(element, :role)],
               :content
             ),
           presentation:
             first_present(
               [group_attr(element, :container, :presentation), attr(element, :presentation)],
               :body
             )
         )
       )}
    end
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [
              :text_input,
              "text_input",
              :numeric_input,
              "numeric_input",
              :date_input,
              "date_input",
              :time_input,
              "time_input"
            ] do
    {:ok,
     renderer_input(kind).(
       element.id,
       Keyword.merge(base_opts(element),
         name: first_present([attr(element, :name), binding_name(element)]),
         value: first_present([attr(element, :value), binding_value(element)]),
         placeholder:
           first_present([group_attr(element, :input, :placeholder), attr(element, :placeholder)]),
         multiline:
           first_present(
             [group_attr(element, :input, :multiline?), attr(element, :multiline)],
             false
           ),
         input_mode:
           first_present(
             [group_attr(element, :input, :input_mode), attr(element, :input_mode)],
             :text
           ),
         min: first_present([group_attr(element, :input, :min), attr(element, :min)]),
         max: first_present([group_attr(element, :input, :max), attr(element, :max)]),
         step: first_present([group_attr(element, :input, :step), attr(element, :step)]),
         format: first_present([group_attr(element, :input, :format), attr(element, :format)])
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:file_input, "file_input"] do
    {:ok,
     Widgets.file_input(
       element.id,
       Keyword.merge(base_opts(element),
         name: first_present([attr(element, :name), binding_name(element)]),
         accept: first_present([group_attr(element, :file, :accept), attr(element, :accept)], []),
         multiple:
           first_present(
             [group_attr(element, :file, :multiple?), attr(element, :multiple)],
             false
           ),
         capture: first_present([group_attr(element, :file, :capture), attr(element, :capture)])
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:slider, "slider"] do
    {:ok,
     Widgets.slider(
       element.id,
       Keyword.merge(base_opts(element),
         name: first_present([attr(element, :name), binding_name(element)]),
         value: first_present([attr(element, :value), binding_value(element)]),
         min: first_present([group_attr(element, :input, :min), attr(element, :min)], 0),
         max: first_present([group_attr(element, :input, :max), attr(element, :max)], 100),
         step: first_present([group_attr(element, :input, :step), attr(element, :step)], 1)
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:toggle, "toggle"] do
    {:ok,
     Widgets.toggle(
       element.id,
       Keyword.merge(base_opts(element),
         name: first_present([attr(element, :name), binding_name(element)]),
         label: first_present([attr(element, :label), content_text(element)]),
         checked: first_present([attr(element, :checked), binding_value(element)], false),
         checked_value:
           first_present(
             [group_attr(element, :input, :checked_value), attr(element, :checked_value)],
             true
           ),
         unchecked_value:
           first_present(
             [group_attr(element, :input, :unchecked_value), attr(element, :unchecked_value)],
             false
           )
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:checkbox, "checkbox"] do
    {:ok,
     Widgets.checkbox(
       element.id,
       first_present([attr(element, :label), content_text(element)], "Checkbox"),
       Keyword.merge(base_opts(element),
         name: first_present([attr(element, :name), binding_name(element)]),
         checked:
           first_present(
             [attr(element, :checked), attr(element, :value), binding_value(element)],
             false
           )
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:select, "select", :radio_group, "radio_group", :pick_list, "pick_list"] do
    {:ok,
     renderer_selection(kind).(
       element.id,
       first_present([group_attr(element, :selection, :options), attr(element, :options)], []),
       Keyword.merge(base_opts(element),
         name: first_present([attr(element, :name), binding_name(element)]),
         value: first_present([attr(element, :value), binding_value(element)]),
         multiple:
           first_present(
             [group_attr(element, :selection, :multiple?), attr(element, :multiple)],
             false
           )
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:menu, "menu"] do
    {:ok,
     Widgets.menu(
       element.id,
       first_present([group_attr(element, :navigation, :items), attr(element, :items)], []),
       Keyword.merge(base_opts(element),
         active_item:
           first_present([
             group_attr(element, :navigation, :active_item),
             attr(element, :active_item)
           ]),
         orientation:
           first_present(
             [group_attr(element, :navigation, :orientation), attr(element, :orientation)],
             :vertical
           )
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:tabs, "tabs"] do
    {:ok,
     Widgets.tabs(
       element.id,
       first_present([group_attr(element, :navigation, :items), attr(element, :items)], []),
       Keyword.merge(base_opts(element),
         active_item:
           first_present([
             group_attr(element, :navigation, :active_item),
             attr(element, :active_item)
           ]),
         orientation:
           first_present(
             [group_attr(element, :navigation, :orientation), attr(element, :orientation)],
             :horizontal
           )
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:list, "list"] do
    {:ok,
     Widgets.list(
       element.id,
       first_present([group_attr(element, :list, :items), attr(element, :items)], []),
       Keyword.merge(base_opts(element),
         ordered:
           first_present([group_attr(element, :list, :ordered?), attr(element, :ordered)], false),
         selection_mode:
           first_present(
             [group_attr(element, :list, :selection_mode), attr(element, :selection_mode)],
             :single
           )
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:table, "table"] do
    sorting = map_attr(element, :sorting)
    pagination = map_attr(element, :pagination)

    {:ok,
     Widgets.table(
       element.id,
       first_present([group_attr(element, :table, :columns), attr(element, :columns)], []),
       first_present([group_attr(element, :table, :rows), attr(element, :rows)], []),
       Keyword.merge(base_opts(element),
         dense:
           first_present([group_attr(element, :table, :dense?), attr(element, :dense)], false),
         selection_mode:
           first_present(
             [group_attr(element, :table, :selection_mode), attr(element, :selection_mode)],
             :single
           ),
         sort_key: attr(element, :sort_key, map_get(sorting, :key)),
         sort_direction: attr(element, :sort_direction, map_get(sorting, :direction)),
         filters: attr(element, :filters, []),
         page: attr(element, :page, map_get(pagination, :page)),
         page_size: attr(element, :page_size, map_get(pagination, :page_size)),
         total_entries: attr(element, :total_entries, map_get(pagination, :total_entries))
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:tree_view, "tree_view"] do
    {:ok,
     Widgets.tree_view(
       element.id,
       first_present([group_attr(element, :tree, :nodes), attr(element, :nodes)], []),
       Keyword.merge(base_opts(element),
         selection_mode:
           first_present(
             [group_attr(element, :tree, :selection_mode), attr(element, :selection_mode)],
             :single
           ),
         filters: attr(element, :filters, []),
         query: attr(element, :query),
         expand_all: attr(element, :expand_all, false)
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:stat, "stat"] do
    {:ok,
     Widgets.stat(
       element.id,
       Keyword.merge(base_opts(element),
         title: first_present([group_attr(element, :stat, :title), attr(element, :title)]),
         value: first_present([group_attr(element, :stat, :value), attr(element, :value)]),
         message: first_present([group_attr(element, :stat, :message), attr(element, :message)])
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:key_value, "key_value"] do
    {:ok,
     Widgets.key_value(
       element.id,
       first_present([group_attr(element, :key_value, :label), attr(element, :label)], ""),
       first_present([group_attr(element, :key_value, :value), attr(element, :value)]),
       Keyword.merge(base_opts(element),
         description:
           first_present([
             group_attr(element, :key_value, :description),
             attr(element, :description)
           ])
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:info_list, "info_list"] do
    {:ok,
     Widgets.info_list(
       element.id,
       first_present([group_attr(element, :info_list, :items), attr(element, :items)], []),
       Keyword.merge(base_opts(element),
         ordered:
           first_present([group_attr(element, :info_list, :ordered?), attr(element, :ordered)], false),
         empty_state:
           first_present([
             group_attr(element, :info_list, :empty_state),
             attr(element, :empty_state)
           ])
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:markdown_viewer, "markdown_viewer"] do
    {:ok,
     Widgets.markdown_viewer(
       element.id,
       attr(element, :source, attr(element, :content, "")),
       Keyword.merge(base_opts(element),
         mode: attr(element, :mode, :rendered),
         anchors: attr(element, :anchors, [])
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:log_viewer, "log_viewer"] do
    pagination = map_attr(element, :pagination)

    {:ok,
     Widgets.log_viewer(
       element.id,
       attr(element, :entries, []),
       Keyword.merge(base_opts(element),
         wrap: attr(element, :wrap, true),
         show_timestamps: attr(element, :show_timestamps, true),
         follow: attr(element, :follow, false),
         filters: attr(element, :filters, []),
         page: attr(element, :page, map_get(pagination, :page)),
         page_size: attr(element, :page_size, map_get(pagination, :page_size)),
         total_entries: attr(element, :total_entries, map_get(pagination, :total_entries))
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:status, "status"] do
    {:ok,
     Widgets.status(
       element.id,
       first_present(
         [group_attr(element, :feedback, :text), content_text(element), attr(element, :text)],
         ""
       ),
       Keyword.merge(base_opts(element),
         severity:
           first_present(
             [group_attr(element, :feedback, :severity), attr(element, :severity)],
             :info
           ),
         status:
           first_present([group_attr(element, :feedback, :status), attr(element, :status)], :idle),
         icon: attr(element, :icon)
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:progress, "progress"] do
    {:ok,
     Widgets.progress(
       element.id,
       Keyword.merge(base_opts(element),
         current:
           first_present([group_attr(element, :progress, :current), attr(element, :current)]),
         total: first_present([group_attr(element, :progress, :total), attr(element, :total)]),
         indeterminate:
           first_present(
             [group_attr(element, :progress, :indeterminate?), attr(element, :indeterminate)],
             false
           ),
         label: first_present([group_attr(element, :progress, :label), attr(element, :label)]),
         severity:
           first_present([group_attr(element, :feedback, :severity), attr(element, :severity)]),
         status: first_present([group_attr(element, :feedback, :status), attr(element, :status)])
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:inline_feedback, "inline_feedback"] do
    {:ok,
     Widgets.inline_feedback(
       element.id,
       first_present(
         [
           group_attr(element, :feedback, :message),
           content_text(element),
           attr(element, :message)
         ],
         ""
       ),
       Keyword.merge(base_opts(element),
         title: first_present([group_attr(element, :feedback, :title), attr(element, :title)]),
         severity:
           first_present(
             [group_attr(element, :feedback, :severity), attr(element, :severity)],
             :info
           ),
         status: first_present([group_attr(element, :feedback, :status), attr(element, :status)])
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:gauge, "gauge"] do
    {:ok,
     Widgets.gauge(
       element.id,
       Keyword.merge(base_opts(element),
         value: first_present([group_attr(element, :gauge, :value), attr(element, :value)]),
         min: first_present([group_attr(element, :gauge, :min), attr(element, :min)], 0),
         max: first_present([group_attr(element, :gauge, :max), attr(element, :max)], 100),
         label: first_present([group_attr(element, :gauge, :label), attr(element, :label)]),
         severity:
           first_present([group_attr(element, :feedback, :severity), attr(element, :severity)]),
         status: first_present([group_attr(element, :feedback, :status), attr(element, :status)])
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:sparkline, "sparkline"] do
    series = attr(element, :series, [])

    {:ok,
     Widgets.sparkline(
       element.id,
       sparkline_values(first_present([group_attr(element, :chart, :series), series], [])),
       Keyword.merge(base_opts(element),
         series_id:
           sparkline_series_id(first_present([group_attr(element, :chart, :series), series], [])),
         axes: first_present([group_attr(element, :chart, :axes), attr(element, :axes)], %{}),
         legend:
           first_present([group_attr(element, :chart, :legend), attr(element, :legend)], %{}),
         scale: first_present([group_attr(element, :chart, :scale), attr(element, :scale)], %{})
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:bar_chart, "bar_chart"] do
    {:ok,
     Widgets.bar_chart(
       element.id,
       first_present([group_attr(element, :chart, :series), attr(element, :series)], []),
       Keyword.merge(base_opts(element),
         axes: first_present([group_attr(element, :chart, :axes), attr(element, :axes)], %{}),
         legend:
           first_present([group_attr(element, :chart, :legend), attr(element, :legend)], %{}),
         scale: first_present([group_attr(element, :chart, :scale), attr(element, :scale)], %{})
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:line_chart, "line_chart"] do
    {:ok,
     Widgets.line_chart(
       element.id,
       first_present([group_attr(element, :chart, :series), attr(element, :series)], []),
       Keyword.merge(base_opts(element),
         axes: first_present([group_attr(element, :chart, :axes), attr(element, :axes)], %{}),
         legend:
           first_present([group_attr(element, :chart, :legend), attr(element, :legend)], %{}),
         scale: first_present([group_attr(element, :chart, :scale), attr(element, :scale)], %{})
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:canvas, "canvas"] do
    {:ok,
     Widgets.canvas(
       element.id,
       first_present([group_attr(element, :canvas, :operations), attr(element, :operations)], []),
       Keyword.merge(base_opts(element),
         width: first_present([group_attr(element, :canvas, :width), attr(element, :width)]),
         height: first_present([group_attr(element, :canvas, :height), attr(element, :height)]),
         unit: first_present([group_attr(element, :canvas, :unit), attr(element, :unit)], :cell),
         background:
           first_present([group_attr(element, :canvas, :background), attr(element, :background)]),
         clip: first_present([group_attr(element, :canvas, :clip?), attr(element, :clip)], true)
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:stream_widget, "stream_widget"] do
    {:ok,
     Widgets.stream_widget(
       element.id,
       first_present([group_attr(element, :stream, :entries), attr(element, :entries)], []),
       Keyword.merge(base_opts(element),
         ordering:
           first_present(
             [group_attr(element, :stream, :ordering), attr(element, :ordering)],
             :append_only
           ),
         severity_field:
           first_present([
             group_attr(element, :stream, :severity_field),
             attr(element, :severity_field)
           ]),
         timestamp_field:
           first_present([
             group_attr(element, :stream, :timestamp_field),
             attr(element, :timestamp_field)
           ])
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:process_monitor, "process_monitor"] do
    {:ok,
     Widgets.process_monitor(
       element.id,
       first_present([group_attr(element, :monitor, :processes), attr(element, :processes)], []),
       Keyword.merge(base_opts(element),
         sort_by:
           first_present([group_attr(element, :monitor, :sort_by), attr(element, :sort_by)]),
         severity:
           first_present([group_attr(element, :monitor, :severity), attr(element, :severity)])
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:cluster_dashboard, "cluster_dashboard"] do
    {:ok,
     Widgets.cluster_dashboard(
       element.id,
       first_present([group_attr(element, :cluster, :nodes), attr(element, :nodes)], []),
       Keyword.merge(base_opts(element),
         summary:
           first_present([group_attr(element, :cluster, :summary), attr(element, :summary)], %{}),
         severity:
           first_present([group_attr(element, :cluster, :severity), attr(element, :severity)])
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:command_palette, "command_palette"] do
    {:ok,
     Widgets.command_palette(
       element.id,
       first_present(
         [group_attr(element, :command_palette, :commands), attr(element, :commands)],
         []
       ),
       Keyword.merge(base_opts(element),
         query:
           first_present([group_attr(element, :command_palette, :query), attr(element, :query)]),
         active_command:
           first_present([
             group_attr(element, :command_palette, :active_command),
             attr(element, :active_command)
           ]),
         placeholder:
           first_present([
             group_attr(element, :command_palette, :placeholder),
             attr(element, :placeholder)
           ])
       )
     )}
  end

  defp do_render(%Element{type: :widget, kind: kind} = element)
       when kind in [:supervision_tree_viewer, "supervision_tree_viewer"] do
    {:ok,
     Widgets.supervision_tree_viewer(
       element.id,
       first_present([group_attr(element, :inspection, :nodes), attr(element, :nodes)], []),
       Keyword.merge(base_opts(element),
         expanded:
           first_present(
             [group_attr(element, :inspection, :expanded?), attr(element, :expanded)],
             true
           ),
         show_restarts:
           first_present(
             [group_attr(element, :inspection, :show_restarts?), attr(element, :show_restarts)],
             true
           )
       )
     )}
  end

  defp do_render(%Element{type: type, kind: kind} = element)
       when type in [:layout, "layout"] and kind in [:row, "row"] do
    with {:ok, children} <- map_children(default_children(element)) do
      {:ok,
       Widgets.row(
         element.id,
         children,
         Keyword.merge(base_opts(element),
           gap: first_present([group_attr(element, :layout, :gap), attr(element, :gap)]),
           align: first_present([group_attr(element, :layout, :align), attr(element, :align)]),
           justify:
             first_present([group_attr(element, :layout, :justify), attr(element, :justify)])
         )
       )}
    end
  end

  defp do_render(%Element{type: type, kind: kind} = element)
       when type in [:layout, "layout"] and kind in [:column, "column", :container, "container"] do
    with {:ok, children} <- map_children(default_children(element)) do
      {:ok,
       Widgets.column(
         element.id,
         children,
         Keyword.merge(base_opts(element),
           gap: first_present([group_attr(element, :layout, :gap), attr(element, :gap)]),
           align: first_present([group_attr(element, :layout, :align), attr(element, :align)]),
           justify:
             first_present([group_attr(element, :layout, :justify), attr(element, :justify)])
         )
       )}
    end
  end

  defp do_render(%Element{type: type, kind: kind} = element)
       when type in [:layout, "layout"] and kind in [:grid, "grid"] do
    with {:ok, children} <- map_children(default_children(element)) do
      {:ok,
       Widgets.grid(
         element.id,
         children,
         Keyword.merge(base_opts(element),
           columns:
             first_present([group_attr(element, :layout, :columns), attr(element, :columns)]),
           rows: first_present([group_attr(element, :layout, :rows), attr(element, :rows)]),
           auto_flow:
             first_present(
               [group_attr(element, :layout, :auto_flow), attr(element, :auto_flow)],
               :row
             ),
           gap: first_present([group_attr(element, :layout, :gap), attr(element, :gap)]),
           align: first_present([group_attr(element, :layout, :align), attr(element, :align)]),
           justify:
             first_present([group_attr(element, :layout, :justify), attr(element, :justify)])
         )
       )}
    end
  end

  defp do_render(%Element{type: type, kind: kind} = element)
       when type in [:layout, "layout"] and kind in [:stack, "stack"] do
    with {:ok, children} <- map_children(default_children(element)) do
      {:ok,
       Widgets.stack(
         element.id,
         children,
         Keyword.merge(base_opts(element),
           direction:
             first_present(
               [group_attr(element, :layout, :direction), attr(element, :direction)],
               :column
             ),
           gap: first_present([group_attr(element, :layout, :gap), attr(element, :gap)])
         )
       )}
    end
  end

  defp do_render(%Element{type: type, kind: kind} = element)
       when type in [:layout, "layout"] and kind in [:panel, "panel"] do
    with {:ok, children} <- map_children(default_children(element)) do
      {:ok,
       Widgets.panel(
         element.id,
         attr(element, :title, "Panel"),
         children,
         Keyword.merge(base_opts(element),
           tone: attr(element, :tone, :default)
         )
       )}
    end
  end

  defp do_render(%Element{type: type, kind: kind} = element)
       when type in [:layout, "layout"] and kind in [:viewport, "viewport"] do
    with {:ok, content} <- required_slot_child(element, :content) do
      {:ok,
       Widgets.viewport(
         element.id,
         content,
         Keyword.merge(base_opts(element),
           axis:
             first_present(
               [group_attr(element, :viewport, :axis), attr(element, :axis)],
               :vertical
             ),
           offset:
             first_present([group_attr(element, :viewport, :offset), attr(element, :offset)], 0),
           clip:
             first_present([group_attr(element, :viewport, :clip?), attr(element, :clip)], true),
           scrollbars:
             first_present(
               [group_attr(element, :viewport, :scrollbars), attr(element, :scrollbars)],
               :auto
             ),
           width: first_present([group_attr(element, :viewport, :width), attr(element, :width)]),
           height:
             first_present([group_attr(element, :viewport, :height), attr(element, :height)]),
           sync_group:
             first_present([
               group_attr(element, :viewport, :sync_group),
               attr(element, :sync_group)
             ]),
           independent_scroll:
             first_present(
               [
                 group_attr(element, :viewport, :independent_scroll?),
                 attr(element, :independent_scroll)
               ],
               false
             )
         )
       )}
    end
  end

  defp do_render(%Element{type: type, kind: kind} = element)
       when type in [:widget, :layout, "widget", "layout"] and kind in [:scroll_bar, "scroll_bar"] do
    {:ok,
     Widgets.scroll_bar(
       element.id,
       Keyword.merge(base_opts(element),
         orientation:
           first_present(
             [group_attr(element, :scroll_bar, :orientation), attr(element, :orientation)],
             :vertical
           ),
         position:
           first_present(
             [group_attr(element, :scroll_bar, :position), attr(element, :position)],
             0
           ),
         viewport_size:
           first_present([
             group_attr(element, :scroll_bar, :viewport_size),
             attr(element, :viewport_size)
           ]),
         content_size:
           first_present([
             group_attr(element, :scroll_bar, :content_size),
             attr(element, :content_size)
           ]),
         viewport_ref:
           first_present([
             group_attr(element, :scroll_bar, :viewport_ref),
             attr(element, :viewport_ref)
           ]),
         sync_group:
           first_present([
             group_attr(element, :scroll_bar, :sync_group),
             attr(element, :sync_group)
           ])
       )
     )}
  end

  defp do_render(%Element{type: type, kind: kind} = element)
       when type in [:layout, "layout"] and kind in [:split_pane, "split_pane"] do
    with {:ok, primary} <- required_slot_child(element, :primary),
         {:ok, secondary} <- required_slot_child(element, :secondary) do
      {:ok,
       Widgets.split_pane(
         element.id,
         primary,
         secondary,
         Keyword.merge(base_opts(element),
           direction:
             first_present(
               [group_attr(element, :split, :direction), attr(element, :direction)],
               :horizontal
             ),
           ratio:
             first_present([group_attr(element, :split, :ratio), attr(element, :ratio)], 0.5),
           resizable:
             first_present(
               [group_attr(element, :split, :resizable?), attr(element, :resizable)],
               true
             ),
           min_primary:
             first_present([
               group_attr(element, :split, :min_primary),
               attr(element, :min_primary)
             ]),
           min_secondary:
             first_present([
               group_attr(element, :split, :min_secondary),
               attr(element, :min_secondary)
             ]),
           primary_size:
             first_present([
               group_attr(element, :split, :primary_size),
               attr(element, :primary_size)
             ]),
           secondary_size:
             first_present([
               group_attr(element, :split, :secondary_size),
               attr(element, :secondary_size)
             ]),
           divider:
             first_present([group_attr(element, :split, :divider), attr(element, :divider)], %{}),
           divider_size: map_get(map_attr(element, :divider), :size),
           divider_style: map_get(map_attr(element, :divider), :style),
           sync_scroll:
             first_present(
               [group_attr(element, :split, :sync_scroll), attr(element, :sync_scroll)],
               false
             )
         )
       )}
    end
  end

  defp do_render(%Element{type: type, kind: kind} = element)
       when type in [:composite, "composite"] and kind in [:form, "form"] do
    with {:ok, children} <- map_children(default_children(element)) do
      {:ok,
       Widgets.form(
         element.id,
         children,
         Keyword.merge(base_opts(element),
           mode:
             first_present([group_attr(element, :form, :mode), attr(element, :mode)], :grouped),
           autocomplete:
             first_present(
               [group_attr(element, :form, :autocomplete?), attr(element, :autocomplete)],
               true
             )
         )
       )}
    end
  end

  defp do_render(%Element{type: type, kind: kind} = element)
       when type in [:composite, "composite"] and kind in [:form_builder, "form_builder"] do
    with {:ok, children} <- map_children(default_children(element)) do
      {:ok,
       Widgets.form_builder(
         element.id,
         children,
         Keyword.merge(base_opts(element),
           mode:
             first_present([group_attr(element, :form, :mode), attr(element, :mode)], :grouped),
           autocomplete:
             first_present(
               [group_attr(element, :form, :autocomplete?), attr(element, :autocomplete)],
               true
             )
         )
       )}
    end
  end

  defp do_render(%Element{type: type, kind: kind} = element)
       when type in [:composite, "composite"] and kind in [:field_group, "field_group"] do
    with {:ok, children} <- map_children(default_children(element)) do
      {:ok,
       Widgets.field_group(
         element.id,
         children,
         Keyword.merge(base_opts(element),
           legend: first_present([group_attr(element, :group, :legend), attr(element, :legend)]),
           group_description:
             first_present([
               group_attr(element, :group, :description),
               attr(element, :description)
             ]),
           collapsible:
             first_present(
               [group_attr(element, :group, :collapsible?), attr(element, :collapsible)],
               false
             )
         )
       )}
    end
  end

  defp do_render(%Element{type: type, kind: kind} = element)
       when type in [:composite, "composite"] and kind in [:field, "field"] do
    with {:ok, control} <- required_slot_child(element, :control) do
      {:ok,
       Widgets.field(
         element.id,
         control,
         Keyword.merge(base_opts(element),
           name: first_present([group_attr(element, :field, :name), attr(element, :name)]),
           control_id:
             first_present([group_attr(element, :field, :control_id), attr(element, :control_id)]),
           label: optional_slot_child(element, :label),
           help: optional_slot_child(element, :help)
         )
       )}
    end
  end

  defp do_render(%Element{type: type, kind: kind} = element)
       when type in [:composite, "composite"] and kind in [:form_field, "form_field"] do
    with {:ok, control} <- required_slot_child(element, :control) do
      {:ok,
       Widgets.form_field(
         element.id,
         control,
         Keyword.merge(base_opts(element),
           name: first_present([group_attr(element, :field, :name), attr(element, :name)]),
           control_id:
             first_present([group_attr(element, :field, :control_id), attr(element, :control_id)]),
           label: optional_slot_child(element, :label),
           help: optional_slot_child(element, :help)
         )
       )}
    end
  end

  defp do_render(%Element{type: type, kind: kind} = element)
       when type in [:layer, :widget, "layer", "widget"] and kind in [:overlay, "overlay"] do
    with {:ok, base} <- required_slot_child(element, :base),
         {:ok, layers} <- required_layer_children(element) do
      {:ok,
       Widgets.overlay(
         element.id,
         base,
         layers,
         Keyword.merge(base_opts(element),
           mode:
             first_present([group_attr(element, :overlay, :mode), attr(element, :mode)], :stacked),
           background_fill:
             first_present(
               [group_attr(element, :overlay, :background_fill), attr(element, :background_fill)],
               :transparent
             ),
           dismissible:
             first_present(
               [group_attr(element, :overlay, :dismissible?), attr(element, :dismissible)],
               true
             ),
           focus_scope:
             first_present([
               group_attr(element, :overlay, :focus_scope),
               attr(element, :focus_scope)
             ]),
           z_order: attr(element, :z_order, :overlay)
         )
       )}
    end
  end

  defp do_render(%Element{type: type, kind: kind} = element)
       when type in [:layer, :widget, "layer", "widget"] and kind in [:dialog, "dialog"] do
    with {:ok, content} <- required_slot_child(element, :content) do
      {:ok,
       Widgets.dialog(
         element.id,
         content,
         Keyword.merge(base_opts(element),
           title: first_present([group_attr(element, :dialog, :title), attr(element, :title)]),
           modal:
             first_present([group_attr(element, :dialog, :modal?), attr(element, :modal)], true),
           dismissible:
             first_present(
               [group_attr(element, :dialog, :dismissible?), attr(element, :dismissible)],
               true
             ),
           size: first_present([group_attr(element, :dialog, :size), attr(element, :size)], :md),
           background_fill:
             first_present(
               [group_attr(element, :dialog, :background_fill), attr(element, :background_fill)],
               :scrim
             ),
           focus_scope:
             first_present(
               [group_attr(element, :dialog, :focus_scope), attr(element, :focus_scope)],
               :dialog
             )
         )
       )}
    end
  end

  defp do_render(%Element{type: type, kind: kind} = element)
       when type in [:layer, :widget, "layer", "widget"] and kind in [:toast, "toast"] do
    with {:ok, content} <- required_slot_child(element, :content) do
      {:ok,
       Widgets.toast(
         element.id,
         content,
         Keyword.merge(base_opts(element),
           placement:
             first_present(
               [group_attr(element, :toast, :placement), attr(element, :placement)],
               :top_end
             ),
           duration_ms:
             first_present(
               [group_attr(element, :toast, :duration_ms), attr(element, :duration_ms)],
               5_000
             ),
           severity:
             first_present(
               [group_attr(element, :toast, :severity), attr(element, :severity)],
               :info
             ),
           transient:
             first_present(
               [group_attr(element, :toast, :transient?), attr(element, :transient)],
               true
             )
         )
       )}
    end
  end

  defp do_render(%Element{type: type, kind: kind} = element)
       when type in [:layer, :widget, "layer", "widget"] and
              kind in [:alert_dialog, "alert_dialog"] do
    with {:ok, content} <- required_slot_child(element, :content) do
      {:ok,
       Widgets.alert_dialog(
         element.id,
         content,
         Keyword.merge(base_opts(element),
           title:
             first_present([group_attr(element, :alert_dialog, :title), attr(element, :title)]),
           severity:
             first_present(
               [group_attr(element, :alert_dialog, :severity), attr(element, :severity)],
               :warning
             ),
           requires_confirmation:
             first_present(
               [
                 group_attr(element, :alert_dialog, :requires_confirmation?),
                 attr(element, :requires_confirmation)
               ],
               true
             ),
           background_fill:
             first_present(
               [
                 group_attr(element, :alert_dialog, :background_fill),
                 attr(element, :background_fill)
               ],
               :scrim
             ),
           focus_scope:
             first_present(
               [group_attr(element, :alert_dialog, :focus_scope), attr(element, :focus_scope)],
               :alert_dialog
             )
         )
       )}
    end
  end

  defp do_render(%Element{type: type, kind: kind} = element)
       when type in [:layer, :widget, "layer", "widget"] and
              kind in [:context_menu, "context_menu"] do
    {:ok,
     Widgets.context_menu(
       element.id,
       context_menu_items(element),
       Keyword.merge(base_opts(element),
         anchor:
           first_present(
             [group_attr(element, :context_menu, :anchor), attr(element, :anchor)],
             %{}
           ),
         placement:
           first_present(
             [group_attr(element, :context_menu, :placement), attr(element, :placement)],
             :bottom_start
           ),
         dismissible:
           first_present(
             [group_attr(element, :context_menu, :dismissible?), attr(element, :dismissible)],
             true
           ),
         background_fill:
           first_present(
             [
               group_attr(element, :context_menu, :background_fill),
               attr(element, :background_fill)
             ],
             :none
           )
       )
     )}
  end

  defp do_render(%Element{} = element) do
    {:error, Error.unsupported_kind(element, ElmUi.Renderer.supported_kinds())}
  end

  defp base_opts(%Element{} = element) do
    styles = canonical_styles(element)
    events = canonical_events(element)

    [
      description: element.metadata && element.metadata.description,
      tags: element.metadata && Map.get(element.metadata, :tags),
      annotations: element.metadata && Map.get(element.metadata, :annotations),
      state: attr(element, :state, %{}),
      styles: styles,
      events: events,
      style_hooks: Map.get(styles, :hooks, []),
      metadata: %{
        canonical_source: %{
          id: element.id,
          type: element.type,
          kind: element.kind
        }
      }
    ]
    |> Enum.reject(fn {_key, value} -> value in [nil, %{}, []] end)
  end

  defp default_children(%Element{} = element) do
    element.children
    |> Enum.filter(fn
      %Child{slot: slot} -> slot in [:default, "default"]
      %Element{} -> true
    end)
  end

  defp map_children(children) do
    children
    |> Enum.reduce_while({:ok, []}, fn child, {:ok, acc} ->
      case render_child(child) do
        {:ok, widget} -> {:cont, {:ok, [widget | acc]}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
    |> case do
      {:ok, widgets} -> {:ok, Enum.reverse(widgets)}
      error -> error
    end
  end

  defp required_slot_child(%Element{} = element, slot) do
    case slot_child(element, slot) do
      {:ok, nil} -> {:error, Error.missing_required_slot(element, slot)}
      {:ok, widget} -> {:ok, widget}
      {:error, error} -> {:error, error}
    end
  end

  defp required_layer_children(%Element{} = element) do
    layers =
      element.children
      |> Enum.filter(fn
        %Child{slot: slot} -> slot in [:layers, "layers"]
        _other -> false
      end)

    layers =
      if layers == [] do
        Enum.filter(element.children, fn
          %Child{slot: slot} -> slot not in [:base, "base"]
          _other -> false
        end)
      else
        layers
      end

    case layers do
      [] -> {:error, Error.missing_required_slot(element, :layers)}
      children -> map_children(children)
    end
  end

  defp optional_slot_child(%Element{} = element, slot) do
    case slot_child(element, slot) do
      {:ok, widget} -> widget
      {:error, _error} -> nil
    end
  end

  defp optional_slot_children(%Element{} = element, slot) do
    element.children
    |> Enum.filter(fn
      %Child{slot: child_slot} -> child_slot == slot or child_slot == Atom.to_string(slot)
      _other -> false
    end)
    |> map_children()
  end

  defp slot_child(%Element{} = element, slot) do
    element.children
    |> Enum.find(fn
      %Child{slot: child_slot} -> child_slot == slot or child_slot == Atom.to_string(slot)
      _other -> false
    end)
    |> case do
      %Child{element: %Element{} = child} ->
        do_render(child)

      %Element{} = child ->
        do_render(child)

      _other ->
        {:ok, nil}
    end
  end

  defp render_child(%Child{element: %Element{} = element}), do: do_render(element)
  defp render_child(%Element{} = element), do: do_render(element)

  defp sparkline_values(series) when is_list(series) do
    case List.first(series) do
      %{values: values} when is_list(values) -> values
      %{"values" => values} when is_list(values) -> values
      first when is_number(first) -> series
      _other -> []
    end
  end

  defp sparkline_values(_series), do: []

  defp sparkline_series_id(series) when is_list(series) do
    case List.first(series) do
      %{id: id} -> id
      %{"id" => id} -> id
      _other -> :primary
    end
  end

  defp sparkline_series_id(_series), do: :primary

  defp renderer_input(kind) when kind in [:text_input, "text_input"], do: &Widgets.text_input/2

  defp renderer_input(kind) when kind in [:numeric_input, "numeric_input"],
    do: &Widgets.numeric_input/2

  defp renderer_input(kind) when kind in [:date_input, "date_input"], do: &Widgets.date_input/2
  defp renderer_input(kind) when kind in [:time_input, "time_input"], do: &Widgets.time_input/2

  defp renderer_selection(kind) when kind in [:select, "select"], do: &Widgets.select/3

  defp renderer_selection(kind) when kind in [:radio_group, "radio_group"],
    do: &Widgets.radio_group/3

  defp renderer_selection(kind) when kind in [:pick_list, "pick_list"], do: &Widgets.pick_list/3

  defp context_menu_items(%Element{} = element) do
    first_present([group_attr(element, :context_menu, :items), attr(element, :items)], []) ||
      case slot_child(element, :menu) do
        {:ok, %ElmUi.Widget{attributes: %{items: items}}} -> items
        _other -> []
      end
  end

  defp binding_name(%Element{} = element) do
    case primary_binding(element) do
      nil ->
        nil

      binding ->
        first_present([map_get(binding, :name), List.last(List.wrap(map_get(binding, :path)))])
    end
  end

  defp binding_value(%Element{} = element) do
    case primary_binding(element) do
      nil -> nil
      binding -> first_present([map_get(binding, :value), map_get(binding, :default)])
    end
  end

  defp primary_binding(%Element{} = element) do
    element
    |> attr(:bindings, [])
    |> List.wrap()
    |> Enum.map(&normalize_map/1)
    |> List.first()
  end

  defp canonical_events(%Element{} = element) do
    interactions =
      element
      |> attr(:interactions, [])
      |> List.wrap()
      |> Enum.map(&normalize_map/1)
      |> Enum.reduce(%{}, fn interaction, acc ->
        case map_get(interaction, :family) do
          nil ->
            acc

          family ->
            Map.put(acc, normalize_key(family), compact_map(Map.delete(interaction, :family)))
        end
      end)

    interactions
    |> Map.merge(normalize_map(attr(element, :events, %{})))
    |> compact_map()
  end

  defp canonical_styles(%Element{} = element) do
    direct_styles = normalize_map(attr(element, :styles, %{}))
    direct_hooks = List.wrap(attr(element, :style_hooks, []))
    translated_style = translate_style_attachment(attr(element, :style, %{}))
    translated_theme = translate_theme_attachment(attr(element, :theme, %{}))

    hooks =
      direct_styles
      |> Map.get(:hooks, [])
      |> List.wrap()
      |> Kernel.++(direct_hooks)
      |> Kernel.++(Map.get(translated_style, :hooks, []))
      |> Kernel.++(Map.get(translated_theme, :hooks, []))
      |> Enum.uniq()

    direct_styles
    |> deep_merge(Map.drop(translated_style, [:hooks]))
    |> deep_merge(Map.drop(translated_theme, [:hooks]))
    |> maybe_put(:hooks, if(hooks == [], do: nil, else: hooks))
    |> compact_map()
  end

  defp translate_style_attachment(style) when style == %{}, do: %{}

  defp translate_style_attachment(style) do
    style = normalize_map(style)
    text = normalize_map(map_get(style, :text, %{}))
    visibility = normalize_map(map_get(style, :visibility, %{}))
    emphasis = normalize_map(map_get(style, :emphasis, %{}))
    state_variants = normalize_map(map_get(style, :state_variants, %{}))

    translated =
      %{}
      |> maybe_put(:tone, map_get(emphasis, :tone))
      |> maybe_put(:visibility, if(map_get(visibility, :hidden?) == true, do: :hidden, else: nil))
      |> maybe_put(:emphasis, text_emphasis(text))
      |> maybe_put(:state_variants, translate_state_variants(state_variants))

    hooks =
      []
      |> maybe_list_add(:state_variants, map_size(Map.get(translated, :state_variants, %{})) > 0)

    maybe_put(translated, :hooks, if(hooks == [], do: nil, else: hooks))
  end

  defp translate_theme_attachment(theme) when theme == %{}, do: %{}

  defp translate_theme_attachment(theme) do
    theme = normalize_map(theme)

    token_refs =
      theme
      |> map_get(:token_refs, [])
      |> List.wrap()
      |> Enum.map(&normalize_map/1)
      |> Enum.map(fn token_ref ->
        path = List.wrap(map_get(token_ref, :path))
        {Enum.join(Enum.map(path, &to_string/1), "_"), path}
      end)
      |> Enum.reject(fn {_key, path} -> path == [] end)
      |> Map.new()

    hooks = [] |> maybe_list_add(:theme_tokens, token_refs != %{})

    %{}
    |> maybe_put(:variant, map_get(theme, :variant))
    |> maybe_put(:theme_tokens, if(token_refs == %{}, do: nil, else: token_refs))
    |> maybe_put(:hooks, if(hooks == [], do: nil, else: hooks))
  end

  defp translate_state_variants(state_variants) when map_size(state_variants) == 0, do: %{}

  defp translate_state_variants(state_variants) do
    Map.new(state_variants, fn {state, value} ->
      {normalize_key(state),
       value |> normalize_map() |> translate_style_attachment() |> Map.drop([:hooks])}
    end)
  end

  defp text_emphasis(text) do
    cond do
      map_get(text, :bold?) == true -> :strong
      map_get(text, :dim?) == true -> :subtle
      true -> nil
    end
  end

  defp content_text(%Element{} = element, default \\ nil) do
    first_present([group_attr(element, :content, :text), attr(element, :content)], default)
  end

  defp group_attr(%Element{} = element, group, key, default \\ nil) do
    case attr(element, group, %{}) do
      value when is_list(value) or is_map(value) or is_struct(value) ->
        value
        |> normalize_map()
        |> map_get(key, default)

      _other ->
        default
    end
  end

  defp first_present(values, default \\ nil) do
    case Enum.reduce_while(values, :not_found, fn value, _acc ->
           if value in [nil, [], %{}] do
             {:cont, :not_found}
           else
             {:halt, value}
           end
         end) do
      :not_found -> default
      value -> value
    end
  end

  defp map_attr(%Element{} = element, key) do
    element
    |> attr(key, %{})
    |> normalize_map()
  end

  defp map_get(map, key, default \\ nil) when is_map(map) do
    cond do
      Map.has_key?(map, key) -> Map.get(map, key)
      Map.has_key?(map, Atom.to_string(key)) -> Map.get(map, Atom.to_string(key))
      true -> default
    end
  end

  defp normalize_key(key) when is_binary(key), do: String.to_atom(key)
  defp normalize_key(key), do: key

  defp normalize_map(nil), do: %{}
  defp normalize_map(%_{} = struct), do: struct |> Map.from_struct() |> normalize_map()
  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(list) when is_list(list), do: Enum.into(list, %{})

  defp attr(%Element{attributes: attrs}, key, default \\ nil) do
    cond do
      Map.has_key?(attrs, key) -> Map.get(attrs, key)
      Map.has_key?(attrs, Atom.to_string(key)) -> Map.get(attrs, Atom.to_string(key))
      true -> default
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, value) when is_map(value) and map_size(value) == 0, do: map
  defp maybe_put(map, _key, []), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> value in [nil, [], %{}] end)
    |> Map.new()
  end

  defp deep_merge(left, right) when left == %{}, do: right
  defp deep_merge(left, right) when right == %{}, do: left

  defp deep_merge(left, right) when is_map(left) and is_map(right) do
    Map.merge(left, right, fn _key, left_value, right_value ->
      if is_map(left_value) and is_map(right_value) do
        deep_merge(left_value, right_value)
      else
        right_value
      end
    end)
  end

  defp maybe_list_add(list, _value, false), do: list
  defp maybe_list_add(list, value, true), do: list ++ [value]
end
