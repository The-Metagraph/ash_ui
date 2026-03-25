defmodule UnifiedUi.Dsl.Entities.Navigation do
  @moduledoc false

  alias UnifiedUi.Dsl.EntitySchema
  alias UnifiedUi.Dsl.Node

  @spec entities() :: [Spark.Dsl.Entity.t()]
  def entities do
    [
      leaf(:menu,
        items: [type: :keyword_list, required: true],
        active_item: [type: :atom, required: false],
        orientation: [type: {:in, [:horizontal, :vertical]}, required: false, default: :vertical]
      ),
      leaf(:tabs,
        items: [type: :keyword_list, required: true],
        active_item: [type: :atom, required: false],
        orientation: [
          type: {:in, [:horizontal, :vertical]},
          required: false,
          default: :horizontal
        ]
      ),
      leaf(:command_palette,
        items: [type: :keyword_list, required: true],
        label: [type: :string, required: false],
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
      auto_set_fields: [family: :navigation, kind: name],
      schema: EntitySchema.widget(extra_schema)
    }
  end
end
