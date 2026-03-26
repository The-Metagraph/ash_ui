defmodule UnifiedUi.Dsl.Entities.Advanced do
  @moduledoc false

  alias UnifiedUi.Dsl.EntitySchema
  alias UnifiedUi.Dsl.Node

  @spec entities() :: [Spark.Dsl.Entity.t()]
  def entities do
    [
      leaf(:stream_widget,
        entries: [type: :any, required: true],
        ordering: [type: :atom, required: false, default: :append_only],
        severity_field: [type: :atom, required: false],
        timestamp_field: [type: :atom, required: false],
        summary: [type: :string, required: false]
      ),
      leaf(:process_monitor,
        processes: [type: :any, required: true],
        sort_by: [type: :atom, required: false],
        severity: [type: :atom, required: false],
        summary: [type: :string, required: false]
      ),
      leaf(:supervision_tree_viewer,
        topology: [type: :any, required: true],
        expanded?: [type: :boolean, required: false, default: true],
        summary: [type: :string, required: false]
      ),
      leaf(:cluster_dashboard,
        cluster_nodes: [type: :any, required: true],
        metrics: [type: :any, required: false],
        severity: [type: :atom, required: false],
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
      auto_set_fields: [family: :advanced, kind: name],
      schema: EntitySchema.widget(extra_schema)
    }
  end
end
