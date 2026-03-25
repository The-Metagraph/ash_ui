defmodule UnifiedUi.Dsl.Entities.Feedback do
  @moduledoc false

  alias UnifiedUi.Dsl.EntitySchema
  alias UnifiedUi.Dsl.Node

  @spec entities() :: [Spark.Dsl.Entity.t()]
  def entities do
    [
      leaf(:status,
        value: [type: :string, required: true],
        severity: [type: :atom, required: false, default: :info],
        status: [type: :atom, required: false, default: :idle],
        summary: [type: :string, required: false]
      ),
      leaf(:progress,
        current: [type: :integer, required: false],
        maximum: [type: :integer, required: false, default: 100],
        label: [type: :string, required: false],
        severity: [type: :atom, required: false],
        status: [type: :atom, required: false],
        indeterminate?: [type: :boolean, required: false, default: false],
        summary: [type: :string, required: false]
      ),
      leaf(:gauge,
        current: [type: :integer, required: true],
        minimum: [type: :integer, required: false, default: 0],
        maximum: [type: :integer, required: false, default: 100],
        label: [type: :string, required: false],
        severity: [type: :atom, required: false],
        status: [type: :atom, required: false],
        summary: [type: :string, required: false]
      ),
      leaf(:inline_feedback,
        title: [type: :string, required: false],
        message: [type: :string, required: true],
        severity: [type: :atom, required: false, default: :info],
        status: [type: :atom, required: false],
        summary: [type: :string, required: false]
      ),
      leaf(:sparkline,
        points: [type: :any, required: true],
        summary: [type: :string, required: false]
      ),
      leaf(:bar_chart,
        series: [type: :any, required: true],
        x_label: [type: :string, required: false],
        y_label: [type: :string, required: false],
        empty_state: [type: :string, required: false],
        summary: [type: :string, required: false]
      ),
      leaf(:line_chart,
        series: [type: :any, required: true],
        x_label: [type: :string, required: false],
        y_label: [type: :string, required: false],
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
      auto_set_fields: [family: :feedback, kind: name],
      schema: EntitySchema.widget(extra_schema)
    }
  end
end
