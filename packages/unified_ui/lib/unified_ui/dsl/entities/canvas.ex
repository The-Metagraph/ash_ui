defmodule UnifiedUi.Dsl.Entities.Canvas do
  @moduledoc false

  alias UnifiedUi.Dsl.EntitySchema
  alias UnifiedUi.Dsl.Node

  @spec entities() :: [Spark.Dsl.Entity.t()]
  def entities do
    [
      %Spark.Dsl.Entity{
        name: :canvas,
        target: Node,
        args: [:id],
        identifier: :id,
        auto_set_fields: [family: :canvas, kind: :canvas],
        schema:
          EntitySchema.widget(
            width: [type: :integer, required: true],
            height: [type: :integer, required: true],
            operations: [type: :any, required: true],
            summary: [type: :string, required: false]
          )
      }
    ]
  end

  @spec kinds() :: [atom()]
  def kinds do
    Enum.map(entities(), & &1.name)
  end
end
