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
       :sparkline,
       :spacer,
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
     ] ++ @component_kinds)
    |> Enum.uniq()
    |> Enum.sort()
  end

  attr(:element, :any, required: true)
  attr(:runtime_state, :any, default: nil)
  attr(:event_target, :any, default: nil)

  def render(%{element: %Element{kind: :unread_badge}} = assigns) do
    assigns =
      assigns
      |> assign(:count_text, unread_badge_count_text(assigns.element))
      |> assign(:badge_tone, unread_badge_tone(assigns.element))
      |> assign(:badge_label, unread_badge_label(assigns.element))
      |> assign(:style_attrs, style_rest(assigns.element))

    ~H"""
    <span
      id={element_id(@element, "unread-badge")}
      data-live-ui-widget="unread-badge"
      data-live-ui-tone={@badge_tone}
      aria-label={@badge_label}
      class={["live-ui-unread-badge", "live-ui-unread-badge-#{@badge_tone}", style_class(@element)]}
      {@style_attrs}
    ><%= @count_text %></span>
    """
  end

  def render(%{element: %Element{kind: :sidebar_item}} = assigns) do
    assigns =
      assigns
      |> assign(:sidebar_state, sidebar_item_state(assigns.element))
      |> assign(:sidebar_kind, sidebar_item_kind(assigns.element))
      |> assign(:sidebar_label, sidebar_item_label(assigns.element))
      |> assign(:sidebar_glyph, sidebar_item_glyph(assigns.element))
      |> assign(:sidebar_meta, sidebar_item_meta(assigns.element))
      |> assign(:sidebar_link, sidebar_item_link(assigns.element))
      |> assign(:style_attrs, style_rest(assigns.element))

    ~H"""
    <%= if @sidebar_link do %>
      <a
        id={element_id(@element, "sidebar-item")}
        href={@sidebar_link}
        data-live-ui-widget="sidebar-item"
        data-live-ui-kind={@sidebar_kind}
        data-live-ui-state={@sidebar_state}
        aria-current={if @sidebar_state == "active", do: "page", else: nil}
        class={[
          "live-ui-sidebar-item",
          "live-ui-sidebar-item-#{@sidebar_state}",
          "live-ui-sidebar-item-#{@sidebar_kind}",
          style_class(@element)
        ]}
        {@style_attrs}
      >
        <span :if={@sidebar_glyph} class="live-ui-sidebar-item-glyph" aria-hidden="true"><%= @sidebar_glyph %></span>
        <span class="live-ui-sidebar-item-label"><%= @sidebar_label %></span>
        <span :if={@sidebar_meta} class="live-ui-sidebar-item-meta"><%= @sidebar_meta %></span>
        <span :if={child_elements(@element, :trailing) != []} class="live-ui-sidebar-item-trailing">
          <%= for child <- child_elements(@element, :trailing) do %>
            <.render element={child} event_target={@event_target} />
          <% end %>
        </span>
      </a>
    <% else %>
      <button
        type="button"
        id={element_id(@element, "sidebar-item")}
        data-live-ui-widget="sidebar-item"
        data-live-ui-kind={@sidebar_kind}
        data-live-ui-state={@sidebar_state}
        aria-current={if @sidebar_state == "active", do: "page", else: nil}
        class={[
          "live-ui-sidebar-item",
          "live-ui-sidebar-item-#{@sidebar_state}",
          "live-ui-sidebar-item-#{@sidebar_kind}",
          style_class(@element)
        ]}
        {@style_attrs}
      >
        <span :if={@sidebar_glyph} class="live-ui-sidebar-item-glyph" aria-hidden="true"><%= @sidebar_glyph %></span>
        <span class="live-ui-sidebar-item-label"><%= @sidebar_label %></span>
        <span :if={@sidebar_meta} class="live-ui-sidebar-item-meta"><%= @sidebar_meta %></span>
        <span :if={child_elements(@element, :trailing) != []} class="live-ui-sidebar-item-trailing">
          <%= for child <- child_elements(@element, :trailing) do %>
            <.render element={child} event_target={@event_target} />
          <% end %>
        </span>
      </button>
    <% end %>
    """
  end

  def render(%{element: %Element{kind: :sidebar_section}} = assigns) do
    assigns =
      assigns
      |> assign(:section_title, sidebar_section_title(assigns.element))
      |> assign(:action_glyph, sidebar_section_action_glyph(assigns.element))
      |> assign(:action_label, sidebar_section_action_label(assigns.element))
      |> assign(:action_copy, sidebar_section_action_copy(assigns.element))
      |> assign(:show_action, sidebar_section_show_action?(assigns.element))
      |> assign(
        :interaction_attrs,
        interaction_event_attrs(assigns.element, Map.get(assigns, :event_target))
      )
      |> assign(:style_attrs, style_rest(assigns.element))

    ~H"""
    <section
      id={element_id(@element, "sidebar-section")}
      data-live-ui-widget="sidebar-section"
      class={["live-ui-sidebar-section", style_class(@element)]}
      {@style_attrs}
    >
      <div class="live-ui-sidebar-section-header">
        <span class="live-ui-sidebar-section-title"><%= @section_title %></span>
        <button
          :if={@show_action}
          type="button"
          class="live-ui-sidebar-section-action"
          aria-label={@action_label}
          title={@action_label}
          {@interaction_attrs}
        ><%= @action_copy %></button>
      </div>
      <div class="live-ui-sidebar-section-body">
        <%= for child <- child_elements(@element) do %>
          <.render element={child} event_target={@event_target} />
        <% end %>
      </div>
    </section>
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

  defp unread_badge_count(%Element{} = element) do
    value = get_in(element.attributes, [:badge, :count])

    cond do
      is_integer(value) and value >= 0 ->
        value

      is_float(value) and value >= 0 ->
        trunc(value)

      is_binary(value) ->
        case Integer.parse(value) do
          {count, ""} when count >= 0 -> count
          _ -> 0
        end

      true ->
        0
    end
  end

  defp unread_badge_count_text(%Element{} = element) do
    case unread_badge_count(element) do
      count when count > 99 -> "99+"
      count -> Integer.to_string(count)
    end
  end

  defp unread_badge_tone(%Element{} = element) do
    case get_in(element.attributes, [:badge, :tone]) do
      tone when tone in [:default, :critical] -> Atom.to_string(tone)
      tone when is_binary(tone) and tone in ["default", "critical"] -> tone
      _other -> style_tone(element) || "default"
    end
  end

  defp unread_badge_label(%Element{} = element) do
    count = unread_badge_count(element)
    suffix = if count == 1, do: "item", else: "items"
    "#{count} unread #{suffix}"
  end

  defp sidebar_item_state(%Element{} = element) do
    element
    |> get_in([Access.key(:attributes, %{}), :sidebar_item, :state])
    |> case do
      state when state in [:default, :active, :blocked] -> Atom.to_string(state)
      _other -> "default"
    end
  end

  defp sidebar_item_kind(%Element{} = element) do
    element
    |> get_in([Access.key(:attributes, %{}), :sidebar_item, :item_kind])
    |> case do
      kind when kind in [:channel, :build, :dm, :draft, :repo] -> Atom.to_string(kind)
      _other -> "channel"
    end
  end

  defp sidebar_item_label(%Element{} = element) do
    string_value(get_in(element.attributes, [:sidebar_item, :label]), "")
  end

  defp sidebar_item_glyph(%Element{} = element) do
    string_optional(get_in(element.attributes, [:sidebar_item, :glyph]))
  end

  defp sidebar_item_meta(%Element{} = element) do
    case get_in(element.attributes, [:sidebar_item, :meta]) do
      nil -> nil
      meta -> to_string(meta)
    end
  end

  defp sidebar_item_link(%Element{} = element) do
    string_optional(get_in(element.attributes, [:sidebar_item, :link_target]))
  end

  defp sidebar_section_title(%Element{} = element) do
    string_value(get_in(element.attributes, [:sidebar_section, :title]), "")
  end

  defp sidebar_section_action_glyph(%Element{} = element) do
    string_optional(get_in(element.attributes, [:sidebar_section, :action_glyph]))
  end

  defp sidebar_section_action_label(%Element{} = element) do
    string_optional(get_in(element.attributes, [:sidebar_section, :action_label]))
  end

  defp sidebar_section_action_copy(%Element{} = element) do
    sidebar_section_action_glyph(element) || sidebar_section_action_label(element) || "+"
  end

  defp sidebar_section_show_action?(%Element{} = element) do
    attrs = get_in(element.attributes, [:sidebar_section]) || %{}

    is_atom(Map.get(attrs, :action_intent)) or
      sidebar_section_action_glyph(element) != nil or
      sidebar_section_action_label(element) != nil
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

  defp primary_control_interaction(%Element{} = element) do
    primary_interaction(element, :change) || primary_interaction(element, :selection)
  end

  defp primary_submit_interaction(%Element{} = element) do
    primary_interaction(element, :submit)
  end

  defp interaction_form_id(%Element{} = element, widget_name) when is_binary(widget_name) do
    "#{element_id(element, widget_name)}-interaction-form"
  end
end
