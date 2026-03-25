defmodule UnifiedUi.Dsl.Entities.Overlay do
  @moduledoc false

  alias UnifiedUi.Dsl.EntitySchema
  alias UnifiedUi.Dsl.Node

  @spec entities() :: [Spark.Dsl.Entity.t()]
  def entities do
    [
      leaf(:context_menu,
        options: [type: :keyword_list, required: true],
        target_ref: [type: :atom, required: true],
        trigger_ref: [type: :atom, required: false],
        placement: [type: :atom, required: false, default: :bottom_start],
        visible?: [type: :boolean, required: false, default: false],
        summary: [type: :string, required: false]
      ),
      leaf(:dialog,
        title: [type: :string, required: true],
        content_ref: [type: :atom, required: true],
        trigger_ref: [type: :atom, required: false],
        visible?: [type: :boolean, required: false, default: false],
        modal?: [type: :boolean, required: false, default: true],
        confirm_intent: [type: :atom, required: false],
        dismiss_intent: [type: :atom, required: false],
        summary: [type: :string, required: false]
      ),
      leaf(:alert_dialog,
        title: [type: :string, required: true],
        message: [type: :string, required: true],
        trigger_ref: [type: :atom, required: false],
        visible?: [type: :boolean, required: false, default: false],
        confirm_intent: [type: :atom, required: true],
        dismiss_intent: [type: :atom, required: true],
        severity: [type: :atom, required: false],
        summary: [type: :string, required: false]
      ),
      leaf(:toast,
        message: [type: :string, required: true],
        title: [type: :string, required: false],
        trigger_ref: [type: :atom, required: false],
        visible?: [type: :boolean, required: false, default: false],
        placement: [type: :atom, required: false, default: :bottom_end],
        severity: [type: :atom, required: false],
        summary: [type: :string, required: false]
      ),
      leaf(:overlay,
        base_ref: [type: :atom, required: true],
        layer_refs: [type: {:list, :atom}, required: true],
        background_fill: [type: :atom, required: false],
        summary: [type: :string, required: false]
      ),
      leaf(:absolute,
        content_ref: [type: :atom, required: true],
        target_ref: [type: :atom, required: true],
        x: [type: :integer, required: true],
        y: [type: :integer, required: true],
        z_index: [type: :integer, required: false, default: 0],
        summary: [type: :string, required: false]
      )
    ]
  end

  @spec kinds() :: [atom()]
  def kinds do
    Enum.map(entities(), & &1.name)
  end

  defp leaf(name, extra_schema) do
    %Spark.Dsl.Entity{
      name: name,
      target: Node,
      args: [:id],
      identifier: :id,
      auto_set_fields: [family: :overlay, kind: name],
      schema: EntitySchema.widget(extra_schema)
    }
  end
end
