defmodule UnifiedUi.Dsl.Entities.Data do
  @moduledoc false

  alias UnifiedUi.Dsl.EntitySchema
  alias UnifiedUi.Dsl.Node

  @spec entities() :: [Spark.Dsl.Entity.t()]
  def entities do
    [
      leaf(:list,
        items: [type: :any, required: true],
        ordered?: [type: :boolean, required: false, default: false],
        selection_mode: [
          type: {:in, [:single, :multiple, :none]},
          required: false,
          default: :single
        ],
        empty_state: [type: :string, required: false],
        summary: [type: :string, required: false]
      ),
      leaf(:table,
        table_columns: [type: :any, required: true],
        table_rows: [type: :any, required: true],
        empty_state: [type: :string, required: false],
        summary: [type: :string, required: false]
      ),
      leaf(:tree_view,
        tree_nodes: [type: :any, required: true],
        expanded?: [type: :boolean, required: false, default: true],
        empty_state: [type: :string, required: false],
        summary: [type: :string, required: false]
      ),
      leaf(:stat,
        title: [type: :string, required: true],
        value: [type: :any, required: true],
        message: [type: :string, required: false],
        summary: [type: :string, required: false]
      ),
      leaf(:key_value,
        label: [type: :string, required: true],
        value: [type: :any, required: true],
        description: [type: :string, required: false],
        summary: [type: :string, required: false]
      ),
      leaf(:info_list,
        items: [type: :any, required: true],
        ordered?: [type: :boolean, required: false, default: false],
        empty_state: [type: :string, required: false],
        summary: [type: :string, required: false]
      ),
      leaf(:markdown_viewer,
        source: [type: :string, required: true],
        presentation: [type: :atom, required: false, default: :rendered],
        summary: [type: :string, required: false]
      ),
      leaf(:log_viewer,
        log_entries: [type: :any, required: true],
        show_timestamps?: [type: :boolean, required: false, default: true],
        wrap?: [type: :boolean, required: false, default: true],
        empty_state: [type: :string, required: false],
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
      auto_set_fields: [family: :data, kind: name],
      schema: EntitySchema.widget(extra_schema)
    }
  end
end
