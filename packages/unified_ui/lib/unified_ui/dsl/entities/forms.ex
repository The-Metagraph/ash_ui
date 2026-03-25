defmodule UnifiedUi.Dsl.Entities.Forms do
  @moduledoc false

  alias UnifiedUi.Dsl.Entities.{Foundational, Input, Navigation}
  alias UnifiedUi.Dsl.EntitySchema
  alias UnifiedUi.Dsl.Node

  @spec entities() :: [Spark.Dsl.Entity.t()]
  def entities do
    top_level_entities() ++ nested_entities()
  end

  @spec top_level_entities() :: [Spark.Dsl.Entity.t()]
  def top_level_entities do
    navigation = Navigation.entities()

    foundational =
      Enum.filter(Foundational.entities(), &(&1.name in [:button, :link, :text, :spacer]))

    [field, form_field, field_group] = nested_entities()

    form_builder =
      form_builder_entity([field, form_field, field_group] ++ foundational ++ navigation)

    [form_builder]
  end

  @spec nested_entities() :: [Spark.Dsl.Entity.t()]
  def nested_entities do
    inputs = Input.entities()
    field = field_entity(:field, inputs)
    form_field = field_entity(:form_field, inputs)
    field_group = field_group_entity([field, form_field])

    [field, form_field, field_group]
  end

  @spec kinds() :: [atom()]
  def kinds do
    Enum.map(entities(), & &1.name)
  end

  defp form_builder_entity(children) do
    %Spark.Dsl.Entity{
      name: :form_builder,
      target: Node,
      args: [:id],
      identifier: :id,
      recursive_as: :children,
      auto_set_fields: [family: :forms, kind: :form_builder],
      entities: [children: children],
      schema:
        EntitySchema.widget(
          summary: [type: :string, required: false],
          submit_intent: [type: :atom, required: false]
        )
    }
  end

  defp field_group_entity(children) do
    %Spark.Dsl.Entity{
      name: :field_group,
      target: Node,
      args: [:id],
      identifier: :id,
      recursive_as: :children,
      auto_set_fields: [family: :forms, kind: :field_group],
      entities: [children: children],
      schema:
        EntitySchema.widget(
          legend: [type: :string, required: false],
          summary: [type: :string, required: false]
        )
    }
  end

  defp field_entity(name, children) do
    %Spark.Dsl.Entity{
      name: name,
      target: Node,
      args: [:id],
      identifier: :id,
      recursive_as: :children,
      auto_set_fields: [family: :forms, kind: name],
      entities: [children: children],
      schema:
        EntitySchema.widget(
          field_name: [type: :atom, required: true],
          label: [type: :string, required: false],
          help: [type: :string, required: false],
          value_path: [type: {:list, :atom}, required: false],
          default_value: [type: :any, required: false]
        )
    }
  end
end
