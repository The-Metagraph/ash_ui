defmodule ElmUi.ServerRuntime.RenderModel do
  @moduledoc """
  Deterministic server-side render model generation for native `elm_ui`
  widgets.
  """

  alias ElmUi.{Widget}
  alias ElmUi.ServerRuntime.StyleResolver

  @spec build(Widget.t()) :: map()
  def build(%Widget{} = widget) do
    build(widget, [])
  end

  @spec build(Widget.t(), keyword()) :: map()
  def build(%Widget{} = widget, opts) do
    resolution = StyleResolver.resolve(widget, theme: Keyword.get(opts, :theme, :default))

    %{
      id: widget.id,
      family: widget.family,
      kind: widget.kind,
      dom: %{
        tag: dom_tag(widget.kind),
        role: dom_role(widget.kind),
        attributes: dom_attributes(widget)
      },
      attributes: widget.attributes,
      state: widget.state,
      styles: widget.styles,
      resolved_styles: resolution.resolved,
      theme: %{
        id: resolution.theme,
        token_refs: resolution.token_refs,
        active_states: resolution.active_states
      },
      events: widget.events,
      metadata: widget.metadata,
      interactions: %{
        interactive?: widget.kind in interactive_kinds() or map_size(widget.events) > 0,
        focusable?: widget.kind in focusable_kinds(),
        editable?: widget.kind in editable_kinds(),
        navigable?: widget.kind in navigable_kinds()
      },
      slots:
        widget.slot_children
        |> Enum.sort_by(fn {slot, _children} -> to_string(slot) end)
        |> Enum.map(fn {slot, children} ->
          %{
            name: slot,
            children: Enum.map(children, &build(&1, opts))
          }
        end),
      diagnostics: %{
        event_names: widget.events |> Map.keys() |> Enum.sort(),
        slot_names: widget.slots |> Enum.map(&to_string/1) |> Enum.sort(),
        style_keys: widget.styles |> Map.keys() |> Enum.map(&to_string/1) |> Enum.sort(),
        style_diagnostics: resolution.diagnostics
      }
    }
  end

  defp dom_tag(:text), do: "span"
  defp dom_tag(:label), do: "label"
  defp dom_tag(:icon), do: "span"
  defp dom_tag(:image), do: "img"
  defp dom_tag(:button), do: "button"
  defp dom_tag(:badge), do: "span"
  defp dom_tag(:hero), do: "section"
  defp dom_tag(:link), do: "a"
  defp dom_tag(:separator), do: "hr"
  defp dom_tag(:spacer), do: "div"
  defp dom_tag(:content), do: "section"
  defp dom_tag(:text_input), do: "input"
  defp dom_tag(:numeric_input), do: "input"
  defp dom_tag(:date_input), do: "input"
  defp dom_tag(:time_input), do: "input"
  defp dom_tag(:file_input), do: "input"
  defp dom_tag(:slider), do: "input"
  defp dom_tag(:toggle), do: "input"
  defp dom_tag(:checkbox), do: "input"
  defp dom_tag(:radio_group), do: "div"
  defp dom_tag(:select), do: "select"
  defp dom_tag(:pick_list), do: "select"
  defp dom_tag(:menu), do: "nav"
  defp dom_tag(:tabs), do: "div"
  defp dom_tag(:row), do: "div"
  defp dom_tag(:column), do: "div"
  defp dom_tag(:grid), do: "div"
  defp dom_tag(:stack), do: "div"
  defp dom_tag(:panel), do: "section"
  defp dom_tag(:form), do: "form"
  defp dom_tag(:form_builder), do: "form"
  defp dom_tag(:field_group), do: "fieldset"
  defp dom_tag(:field), do: "div"
  defp dom_tag(:form_field), do: "div"
  defp dom_tag(:viewport), do: "div"
  defp dom_tag(:scroll_bar), do: "div"
  defp dom_tag(:split_pane), do: "div"
  defp dom_tag(:overlay), do: "div"
  defp dom_tag(:dialog), do: "dialog"
  defp dom_tag(:toast), do: "aside"
  defp dom_tag(:alert_dialog), do: "dialog"
  defp dom_tag(:context_menu), do: "div"
  defp dom_tag(:list), do: "ul"
  defp dom_tag(:table), do: "table"
  defp dom_tag(:tree_view), do: "ul"
  defp dom_tag(:stat), do: "section"
  defp dom_tag(:key_value), do: "dl"
  defp dom_tag(:info_list), do: "ul"
  defp dom_tag(:markdown_viewer), do: "article"
  defp dom_tag(:log_viewer), do: "pre"
  defp dom_tag(:status), do: "div"
  defp dom_tag(:progress), do: "progress"
  defp dom_tag(:inline_feedback), do: "aside"
  defp dom_tag(:gauge), do: "figure"
  defp dom_tag(:sparkline), do: "figure"
  defp dom_tag(:bar_chart), do: "figure"
  defp dom_tag(:line_chart), do: "figure"
  defp dom_tag(:canvas), do: "canvas"
  defp dom_tag(:stream_widget), do: "section"
  defp dom_tag(:process_monitor), do: "section"
  defp dom_tag(:cluster_dashboard), do: "section"
  defp dom_tag(:command_palette), do: "section"
  defp dom_tag(:supervision_tree_viewer), do: "section"
  defp dom_tag(_kind), do: "div"

  defp dom_role(:text), do: "text"
  defp dom_role(:label), do: "label"
  defp dom_role(:button), do: "button"
  defp dom_role(:badge), do: "status"
  defp dom_role(:hero), do: "region"
  defp dom_role(:link), do: "link"
  defp dom_role(:text_input), do: "textbox"
  defp dom_role(:numeric_input), do: "spinbutton"
  defp dom_role(:date_input), do: "textbox"
  defp dom_role(:time_input), do: "textbox"
  defp dom_role(:file_input), do: "textbox"
  defp dom_role(:slider), do: "slider"
  defp dom_role(:toggle), do: "switch"
  defp dom_role(:checkbox), do: "checkbox"
  defp dom_role(:radio_group), do: "radiogroup"
  defp dom_role(:select), do: "listbox"
  defp dom_role(:pick_list), do: "listbox"
  defp dom_role(:menu), do: "navigation"
  defp dom_role(:tabs), do: "tablist"
  defp dom_role(:grid), do: "grid"
  defp dom_role(:form), do: "form"
  defp dom_role(:form_builder), do: "form"
  defp dom_role(:field_group), do: "group"
  defp dom_role(:field), do: "group"
  defp dom_role(:form_field), do: "group"
  defp dom_role(:panel), do: "region"
  defp dom_role(:viewport), do: "region"
  defp dom_role(:scroll_bar), do: "scrollbar"
  defp dom_role(:split_pane), do: "group"
  defp dom_role(:overlay), do: "presentation"
  defp dom_role(:dialog), do: "dialog"
  defp dom_role(:toast), do: "status"
  defp dom_role(:alert_dialog), do: "alertdialog"
  defp dom_role(:context_menu), do: "menu"
  defp dom_role(:list), do: "list"
  defp dom_role(:table), do: "grid"
  defp dom_role(:tree_view), do: "tree"
  defp dom_role(:stat), do: "status"
  defp dom_role(:key_value), do: "list"
  defp dom_role(:info_list), do: "list"
  defp dom_role(:markdown_viewer), do: "document"
  defp dom_role(:log_viewer), do: "log"
  defp dom_role(:status), do: "status"
  defp dom_role(:progress), do: "progressbar"
  defp dom_role(:inline_feedback), do: "alert"
  defp dom_role(:gauge), do: "img"
  defp dom_role(:sparkline), do: "img"
  defp dom_role(:bar_chart), do: "img"
  defp dom_role(:line_chart), do: "img"
  defp dom_role(:canvas), do: "img"
  defp dom_role(:stream_widget), do: "log"
  defp dom_role(:process_monitor), do: "table"
  defp dom_role(:cluster_dashboard), do: "region"
  defp dom_role(:command_palette), do: "combobox"
  defp dom_role(:supervision_tree_viewer), do: "tree"
  defp dom_role(_kind), do: "presentation"

  defp dom_attributes(%Widget{} = widget) do
    %{
      id: widget.id,
      class_tokens: List.wrap(widget.styles[:hooks]),
      disabled: Map.get(widget.state, :disabled, false)
    }
    |> maybe_put(:href, Map.get(widget.attributes, :href))
    |> maybe_put(:value, Map.get(widget.attributes, :value))
    |> maybe_put(:name, Map.get(widget.attributes, :name))
    |> maybe_put(:for, Map.get(widget.attributes, :for))
    |> maybe_put(:placeholder, Map.get(widget.attributes, :placeholder))
    |> maybe_put(:orientation, Map.get(widget.attributes, :orientation))
    |> maybe_put(:active_item, Map.get(widget.attributes, :active_item))
    |> maybe_put(:legend, Map.get(widget.attributes, :legend))
    |> maybe_put(:open, Map.get(widget.state, :open))
    |> maybe_put(:modal, Map.get(widget.attributes, :modal))
    |> maybe_put(:title, Map.get(widget.attributes, :title))
    |> maybe_put(:placement, Map.get(widget.attributes, :placement))
    |> maybe_put(:viewport_ref, Map.get(widget.attributes, :viewport_ref))
    |> maybe_put(:ratio, Map.get(widget.attributes, :ratio))
    |> maybe_put(:value, dom_value(widget))
    |> maybe_put(:max, dom_max(widget))
  end

  defp interactive_kinds do
    [
      :button,
      :link,
      :text_input,
      :numeric_input,
      :date_input,
      :time_input,
      :file_input,
      :slider,
      :toggle,
      :checkbox,
      :radio_group,
      :select,
      :pick_list,
      :menu,
      :tabs,
      :form,
      :form_builder,
      :viewport,
      :scroll_bar,
      :split_pane,
      :overlay,
      :dialog,
      :toast,
      :alert_dialog,
      :context_menu,
      :table,
      :tree_view,
      :log_viewer,
      :stream_widget,
      :process_monitor,
      :command_palette,
      :supervision_tree_viewer
    ]
  end

  defp focusable_kinds do
    [
      :button,
      :link,
      :text_input,
      :numeric_input,
      :date_input,
      :time_input,
      :file_input,
      :slider,
      :toggle,
      :checkbox,
      :radio_group,
      :select,
      :pick_list,
      :menu,
      :tabs,
      :form_builder,
      :viewport,
      :scroll_bar,
      :split_pane,
      :dialog,
      :alert_dialog,
      :context_menu,
      :table,
      :tree_view,
      :log_viewer,
      :stream_widget,
      :process_monitor,
      :command_palette,
      :supervision_tree_viewer
    ]
  end

  defp editable_kinds do
    [
      :text_input,
      :numeric_input,
      :date_input,
      :time_input,
      :file_input,
      :slider,
      :toggle,
      :checkbox,
      :radio_group,
      :select,
      :pick_list,
      :command_palette
    ]
  end

  defp navigable_kinds do
    [:link, :menu, :tabs, :tree_view, :context_menu, :list]
  end

  defp dom_value(%Widget{kind: :progress, attributes: attributes}) do
    Map.get(attributes, :current)
  end

  defp dom_value(%Widget{kind: :gauge, attributes: attributes}) do
    Map.get(attributes, :value)
  end

  defp dom_value(%Widget{attributes: attributes}) do
    Map.get(attributes, :value)
  end

  defp dom_max(%Widget{kind: :progress, attributes: attributes}) do
    Map.get(attributes, :total)
  end

  defp dom_max(%Widget{kind: :gauge, attributes: attributes}) do
    Map.get(attributes, :max)
  end

  defp dom_max(%Widget{}) do
    nil
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
