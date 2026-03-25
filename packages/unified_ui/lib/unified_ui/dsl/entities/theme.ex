defmodule UnifiedUi.Dsl.Entities.Theme do
  @moduledoc false

  alias UnifiedUi.Theme

  @spec entities() :: [Spark.Dsl.Entity.t()]
  def entities do
    [theme_entity()]
  end

  defp theme_entity do
    %Spark.Dsl.Entity{
      name: :theme,
      target: Theme,
      identifier: :id,
      recursive_as: :children,
      entities: [
        children: [
          palette_color_entity(),
          semantic_role_entity(),
          token_entity(),
          component_style_entity()
        ]
      ],
      schema: [
        id: [type: :atom, required: true],
        description: [type: :string, required: false],
        authored_ref: [type: {:list, :atom}, required: false],
        summary: [type: :string, required: false],
        extends: [type: :atom, required: false],
        inherit?: [type: :boolean, required: false, default: true]
      ]
    }
  end

  defp palette_color_entity do
    %Spark.Dsl.Entity{
      name: :palette_color,
      target: Theme.PaletteColor,
      identifier: :id,
      schema: [
        id: [type: :atom, required: true],
        color: [type: :any, required: true],
        summary: [type: :string, required: false]
      ]
    }
  end

  defp semantic_role_entity do
    %Spark.Dsl.Entity{
      name: :semantic_role,
      target: Theme.SemanticRole,
      identifier: :id,
      schema: [
        id: [type: :atom, required: true],
        value: [type: :any, required: true],
        summary: [type: :string, required: false]
      ]
    }
  end

  defp token_entity do
    %Spark.Dsl.Entity{
      name: :token,
      target: Theme.TokenDeclaration,
      identifier: :id,
      schema: [
        id: [type: :atom, required: true],
        value: [type: :any, required: true],
        summary: [type: :string, required: false]
      ]
    }
  end

  defp component_style_entity do
    %Spark.Dsl.Entity{
      name: :component_style,
      target: Theme.ComponentStyle,
      identifier: :id,
      schema: [
        id: [type: :atom, required: true],
        component: [type: :atom, required: true],
        variant: [type: :atom, required: false],
        state: [type: :atom, required: false],
        style: [type: :any, required: false],
        token_refs: [type: {:list, :any}, required: false, default: []],
        inherit?: [type: :boolean, required: false, default: true],
        summary: [type: :string, required: false]
      ]
    }
  end
end
