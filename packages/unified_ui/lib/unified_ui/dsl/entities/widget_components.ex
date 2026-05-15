defmodule UnifiedUi.Dsl.Entities.WidgetComponents do
  @moduledoc false

  alias UnifiedUi.Dsl.Entities.Foundational
  alias UnifiedUi.Dsl.EntitySchema
  alias UnifiedUi.Dsl.Node

  @content_identity_family :content_identity_and_disclosure
  @form_control_family :form_control_and_composer
  @row_artifact_family :row_and_artifact
  @workflow_family :workflow_progress_and_status
  @layer_family :layer_shell_and_callout
  @redline_code_family :redline_and_code
  @composition_behavior_family :composition_behavior

  @spec entities() :: [Spark.Dsl.Entity.t()]
  def entities do
    content_identity_entities() ++
      form_control_entities() ++
      row_artifact_entities() ++
      workflow_entities() ++
      layer_callout_entities() ++
      redline_code_entities() ++
      composition_behavior_entities()
  end

  @spec content_identity_entities() :: [Spark.Dsl.Entity.t()]
  def content_identity_entities do
    [
      leaf(
        :inline_rich_text_heading,
        @content_identity_family,
        level: [type: {:in, [:h1, :h2, :h3, :h4, :h5, :h6]}, required: false, default: :h1],
        segments: [type: :any, required: true],
        summary: [type: :string, required: false]
      ),
      disclosure_entity(),
      leaf(
        :kicker,
        @content_identity_family,
        items: [type: :any, required: true],
        separator: [type: :string, required: false, default: "·"],
        summary: [type: :string, required: false]
      ),
      leaf(
        :avatar,
        @content_identity_family,
        initials: [type: :string, required: false],
        image_source: [type: :string, required: false],
        size: [type: {:in, [:small, :medium, :large]}, required: false, default: :medium],
        shape: [type: {:in, [:round, :square]}, required: false, default: :round],
        summary: [type: :string, required: false]
      ),
      leaf(
        :presence_dot,
        @content_identity_family,
        state: [type: :atom, required: false, default: :quiet],
        size: [type: {:in, [:small, :medium, :large]}, required: false, default: :medium],
        summary: [type: :string, required: false]
      ),
      leaf(
        :unread_badge,
        @content_identity_family,
        count: [type: :integer, required: true],
        tone: [type: {:in, [:default, :critical]}, required: false, default: :default],
        summary: [type: :string, required: false]
      )
    ]
  end

  @spec form_control_entities() :: [Spark.Dsl.Entity.t()]
  def form_control_entities do
    [
      leaf(
        :segmented_button_group,
        @form_control_family,
        options: [type: :any, required: true],
        active_value: [type: :any, required: false],
        selection_intent: [type: :atom, required: false],
        summary: [type: :string, required: false]
      ),
      leaf(
        :runtime_form_shell,
        @form_control_family,
        fields: [type: :any, required: true],
        submit_label: [type: :string, required: false],
        submit_intent: [type: :atom, required: false],
        change_intent: [type: :atom, required: false],
        validation_state: [type: :atom, required: false],
        summary: [type: :string, required: false]
      ),
      chat_composer_entity()
    ]
  end

  @spec row_artifact_entities() :: [Spark.Dsl.Entity.t()]
  def row_artifact_entities do
    [
      container(
        :list_item_multi_column,
        @row_artifact_family,
        row_identity: [type: :any, required: true],
        column_template: [type: :any, required: true],
        active?: [type: :boolean, required: false, default: false],
        link_target: [type: :string, required: false],
        action_intent: [type: :atom, required: false],
        summary: [type: :string, required: false]
      ),
      container(
        :artifact_row,
        @row_artifact_family,
        title: [type: :string, required: true],
        meta: [type: :any, required: false],
        row_identity: [type: :any, required: true],
        active?: [type: :boolean, required: false, default: false],
        link_target: [type: :string, required: false],
        action_intent: [type: :atom, required: false],
        summary: [type: :string, required: false]
      )
    ]
  end

  @spec workflow_entities() :: [Spark.Dsl.Entity.t()]
  def workflow_entities do
    [
      leaf(
        :pipeline_stepper_horizontal,
        @workflow_family,
        steps: [type: :any, required: true],
        active_index: [type: :integer, required: false, default: 0],
        completed_indices: [type: :any, required: false, default: []],
        navigation_intent: [type: :atom, required: false],
        summary: [type: :string, required: false]
      ),
      leaf(
        :segmented_progress_bar,
        @workflow_family,
        segments: [type: :any, required: true],
        aggregate_progress: [type: :any, required: false],
        label: [type: :string, required: false],
        summary: [type: :string, required: false]
      ),
      leaf(
        :workflow_stage_list_vertical,
        @workflow_family,
        stages: [type: :any, required: true],
        active_index: [type: :integer, required: false, default: 0],
        summary: [type: :string, required: false]
      ),
      leaf(
        :meter_thin,
        @workflow_family,
        current: [type: :any, required: true],
        minimum: [type: :any, required: false, default: 0],
        maximum: [type: :any, required: false, default: 100],
        label: [type: :string, required: false],
        state: [type: :atom, required: false],
        summary: [type: :string, required: false]
      )
    ]
  end

  @spec layer_callout_entities() :: [Spark.Dsl.Entity.t()]
  def layer_callout_entities do
    [
      container(
        :sticky_frosted_header,
        @layer_family,
        title: [type: :string, required: true],
        leading: [type: :any, required: false, default: []],
        trailing: [type: :any, required: false, default: []],
        summary: [type: :string, required: false]
      ),
      container(
        :slide_over_panel,
        @layer_family,
        open?: [type: :boolean, required: false, default: false],
        size: [type: {:in, [:small, :medium, :large, :wide]}, required: false, default: :medium],
        modal?: [type: :boolean, required: false, default: false],
        dismiss_intent: [type: :atom, required: false],
        summary: [type: :string, required: false]
      ),
      container(
        :event_callout,
        @layer_family,
        tone: [type: :atom, required: false, default: :info],
        eyebrow: [type: :string, required: false],
        title: [type: :string, required: false],
        message: [type: :string, required: true],
        action_intent: [type: :atom, required: false],
        summary: [type: :string, required: false]
      )
    ]
  end

  @spec redline_code_entities() :: [Spark.Dsl.Entity.t()]
  def redline_code_entities do
    [
      leaf(
        :redline_inline,
        @redline_code_family,
        segments: [type: :any, required: true],
        text_safety: [type: :atom, required: false, default: :plain_text],
        summary: [type: :string, required: false]
      ),
      leaf(
        :code_block_syntax_highlighted,
        @redline_code_family,
        language: [type: :any, required: true],
        tokens: [type: :any, required: true],
        text_safety: [type: :atom, required: false, default: :plain_text],
        summary: [type: :string, required: false]
      )
    ]
  end

  @spec composition_behavior_entities() :: [Spark.Dsl.Entity.t()]
  def composition_behavior_entities do
    [list_repeat_entity()]
  end

  @spec content_identity_kinds() :: [atom()]
  def content_identity_kinds do
    Enum.map(content_identity_entities(), & &1.name)
  end

  @spec form_control_kinds() :: [atom()]
  def form_control_kinds do
    Enum.map(form_control_entities(), & &1.name)
  end

  @spec row_artifact_kinds() :: [atom()]
  def row_artifact_kinds do
    Enum.map(row_artifact_entities(), & &1.name)
  end

  @spec workflow_kinds() :: [atom()]
  def workflow_kinds do
    Enum.map(workflow_entities(), & &1.name)
  end

  @spec layer_callout_kinds() :: [atom()]
  def layer_callout_kinds do
    Enum.map(layer_callout_entities(), & &1.name)
  end

  @spec redline_code_kinds() :: [atom()]
  def redline_code_kinds do
    Enum.map(redline_code_entities(), & &1.name)
  end

  @spec composition_behavior_kinds() :: [atom()]
  def composition_behavior_kinds do
    Enum.map(composition_behavior_entities(), & &1.name)
  end

  @spec kinds() :: [atom()]
  def kinds do
    content_identity_kinds() ++
      form_control_kinds() ++
      row_artifact_kinds() ++
      workflow_kinds() ++
      layer_callout_kinds() ++
      redline_code_kinds() ++
      composition_behavior_kinds()
  end

  defp leaf(name, family, extra_schema) do
    %Spark.Dsl.Entity{
      name: name,
      target: Node,
      args: [:id],
      identifier: :id,
      auto_set_fields: [family: family, kind: name],
      schema: EntitySchema.widget(extra_schema)
    }
  end

  defp container(name, family, extra_schema) do
    %Spark.Dsl.Entity{
      name: name,
      target: Node,
      args: [:id],
      identifier: :id,
      recursive_as: :children,
      auto_set_fields: [family: family, kind: name],
      entities: [children: Foundational.entities()],
      schema: EntitySchema.widget(extra_schema)
    }
  end

  defp disclosure_entity do
    %Spark.Dsl.Entity{
      name: :disclosure,
      target: Node,
      args: [:id],
      identifier: :id,
      recursive_as: :children,
      auto_set_fields: [family: @content_identity_family, kind: :disclosure],
      entities: [children: Foundational.entities()],
      schema:
        EntitySchema.widget(
          summary: [type: :string, required: true],
          open?: [type: :boolean, required: false, default: false]
        )
    }
  end

  defp chat_composer_entity do
    %Spark.Dsl.Entity{
      name: :chat_composer,
      target: Node,
      args: [:id],
      identifier: :id,
      recursive_as: :children,
      auto_set_fields: [family: @form_control_family, kind: :chat_composer],
      entities: [children: Foundational.entities()],
      schema:
        EntitySchema.widget(
          name: [type: :atom, required: false],
          value: [type: :string, required: false],
          placeholder: [type: :string, required: false],
          rows: [type: :integer, required: false, default: 3],
          send_label: [type: :string, required: false, default: "Send"],
          send_intent: [type: :atom, required: true],
          change_intent: [type: :atom, required: false],
          summary: [type: :string, required: false]
        )
    }
  end

  defp list_repeat_entity do
    %Spark.Dsl.Entity{
      name: :list_repeat,
      target: Node,
      args: [:id],
      identifier: :id,
      recursive_as: :children,
      auto_set_fields: [family: @composition_behavior_family, kind: :list_repeat],
      entities: [
        children: [
          template_container(
            :list_item_multi_column_template,
            :list_item_multi_column,
            @row_artifact_family,
            row_identity: [type: :any, required: true],
            column_template: [type: :any, required: true],
            active?: [type: :boolean, required: false, default: false],
            link_target: [type: :string, required: false],
            action_intent: [type: :atom, required: false],
            summary: [type: :string, required: false]
          ),
          template_container(
            :artifact_row_template,
            :artifact_row,
            @row_artifact_family,
            title: [type: :string, required: true],
            meta: [type: :any, required: false],
            row_identity: [type: :any, required: true],
            active?: [type: :boolean, required: false, default: false],
            link_target: [type: :string, required: false],
            action_intent: [type: :atom, required: false],
            summary: [type: :string, required: false]
          ),
          template_container(
            :event_callout_template,
            :event_callout,
            @layer_family,
            tone: [type: :atom, required: false, default: :info],
            eyebrow: [type: :string, required: false],
            title: [type: :string, required: false],
            message: [type: :string, required: true],
            action_intent: [type: :atom, required: false],
            summary: [type: :string, required: false]
          )
        ]
      ],
      schema:
        EntitySchema.widget(
          repeat_binding: [type: :atom, required: true],
          row_scope: [type: :atom, required: false, default: :row],
          row_fields: [type: :any, required: false, default: []],
          template_identity: [type: :atom, required: false],
          identity_strategy: [
            type: {:in, [:row_identity, :index, :stable_hash]},
            required: false,
            default: :row_identity
          ],
          summary: [type: :string, required: false]
        )
    }
  end

  defp template_container(name, kind, family, extra_schema) do
    %Spark.Dsl.Entity{
      name: name,
      target: Node,
      args: [:id],
      identifier: :id,
      recursive_as: :children,
      auto_set_fields: [family: family, kind: kind],
      entities: [children: Foundational.entities()],
      schema: EntitySchema.widget(extra_schema)
    }
  end
end
