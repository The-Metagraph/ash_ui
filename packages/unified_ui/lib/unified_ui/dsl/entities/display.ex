defmodule UnifiedUi.Dsl.Entities.Display do
  @moduledoc false

  alias UnifiedUi.Dsl.EntitySchema
  alias UnifiedUi.Dsl.Node

  @spec entities() :: [Spark.Dsl.Entity.t()]
  def entities do
    [
      leaf(:scroll_bar,
        target_ref: [type: :atom, required: true],
        position: [type: :integer, required: true],
        viewport_size: [type: :integer, required: true],
        content_size: [type: :integer, required: true],
        orientation: [
          type: {:in, [:horizontal, :vertical]},
          required: false,
          default: :vertical
        ],
        summary: [type: :string, required: false]
      ),
      leaf(:split_pane,
        primary_ref: [type: :atom, required: true],
        secondary_ref: [type: :atom, required: true],
        ratio: [type: :float, required: false, default: 0.5],
        orientation: [
          type: {:in, [:horizontal, :vertical]},
          required: false,
          default: :horizontal
        ],
        divider_size: [type: :integer, required: false, default: 1],
        divider_style: [type: :atom, required: false, default: :solid],
        summary: [type: :string, required: false]
      ),
      leaf(:viewport,
        content_ref: [type: :atom, required: true],
        width: [type: :integer, required: true],
        height: [type: :integer, required: true],
        offset: [type: :any, required: false, default: {0, 0}],
        clip?: [type: :boolean, required: false, default: true],
        summary: [type: :string, required: false]
      ),
      leaf(:scroll_region,
        content_ref: [type: :atom, required: true],
        height: [type: :integer, required: true],
        offset: [type: :integer, required: false, default: 0],
        clip?: [type: :boolean, required: false, default: true],
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
      auto_set_fields: [family: :display, kind: name],
      schema: EntitySchema.widget(extra_schema)
    }
  end
end
