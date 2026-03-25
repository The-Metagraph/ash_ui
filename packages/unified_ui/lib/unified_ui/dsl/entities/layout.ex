defmodule UnifiedUi.Dsl.Entities.Layout do
  @moduledoc false

  alias UnifiedUi.Dsl.Entities.{
    Advanced,
    Canvas,
    Data,
    Display,
    Feedback,
    Foundational,
    Input,
    Navigation,
    Overlay
  }

  alias UnifiedUi.Dsl.EntitySchema
  alias UnifiedUi.Dsl.Node

  @spec entities() :: [Spark.Dsl.Entity.t()]
  def entities do
    children =
      Foundational.entities() ++
        Input.entities() ++
        Navigation.entities() ++
        Data.entities() ++
        Feedback.entities() ++
        Advanced.entities() ++
        Overlay.entities() ++
        Display.entities() ++
        Canvas.entities()

    [
      layout(:box, children,
        summary: [type: :string, required: false],
        gap: [type: :atom, required: false]
      ),
      layout(:row, children,
        summary: [type: :string, required: false],
        gap: [type: :atom, required: false],
        align: [type: :atom, required: false],
        justify: [type: :atom, required: false]
      ),
      layout(:column, children,
        summary: [type: :string, required: false],
        gap: [type: :atom, required: false],
        align: [type: :atom, required: false],
        justify: [type: :atom, required: false]
      ),
      layout(:grid, children,
        summary: [type: :string, required: false],
        gap: [type: :atom, required: false],
        columns: [type: :integer, required: false],
        rows: [type: :integer, required: false]
      ),
      layout(:stack, children,
        summary: [type: :string, required: false],
        gap: [type: :atom, required: false],
        align: [type: :atom, required: false]
      )
    ]
  end

  @spec kinds() :: [atom()]
  def kinds do
    Enum.map(entities(), & &1.name)
  end

  defp layout(name, children, extra_schema) do
    %Spark.Dsl.Entity{
      name: name,
      target: Node,
      args: [:id],
      identifier: :id,
      recursive_as: :children,
      auto_set_fields: [family: :layout, kind: name],
      entities: [children: children],
      schema: EntitySchema.widget(extra_schema)
    }
  end
end
