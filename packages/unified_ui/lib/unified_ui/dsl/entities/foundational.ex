defmodule UnifiedUi.Dsl.Entities.Foundational do
  @moduledoc false

  alias UnifiedUi.Dsl.EntitySchema
  alias UnifiedUi.Dsl.Node

  @spec entities() :: [Spark.Dsl.Entity.t()]
  def entities do
    text =
      leaf(:text,
        value: [type: :string, required: true],
        role: [type: :atom, required: false, default: :text]
      )

    label =
      leaf(:label,
        value: [type: :string, required: true],
        target: [type: :atom, required: false]
      )

    icon =
      leaf(:icon,
        name: [type: :atom, required: true],
        set: [type: :atom, required: false],
        fallback_text: [type: :string, required: false]
      )

    image =
      leaf(:image,
        source: [type: :string, required: true],
        alt_text: [type: :string, required: false],
        media_type: [type: :string, required: false],
        fit: [type: :atom, required: false]
      )

    badge =
      leaf(:badge,
        value: [type: :string, required: true],
        name: [type: :atom, required: false],
        set: [type: :atom, required: false],
        presentation: [type: :atom, required: false, default: :pill]
      )

    button =
      leaf(:button,
        label: [type: :string, required: true],
        action_intent: [type: :atom, required: false],
        emphasis: [type: :atom, required: false]
      )

    link =
      leaf(:link,
        label: [type: :string, required: true],
        target: [type: :string, required: true],
        external?: [type: :boolean, required: false, default: false],
        target_kind: [type: :atom, required: false, default: :uri],
        navigation_target: [type: :string, required: false]
      )

    separator =
      leaf(:separator,
        orientation: [
          type: {:in, [:horizontal, :vertical]},
          required: false,
          default: :horizontal
        ],
        decorative?: [type: :boolean, required: false, default: true]
      )

    spacer =
      leaf(:spacer,
        size: [type: {:in, [:xs, :sm, :md, :lg, :xl]}, required: false, default: :md],
        grow: [type: :integer, required: false, default: 0]
      )

    leafs = [text, label, icon, image, badge, button, link, separator, spacer]

    content =
      %Spark.Dsl.Entity{
        name: :content,
        target: Node,
        args: [:id],
        identifier: :id,
        recursive_as: :children,
        auto_set_fields: [family: :foundational, kind: :content],
        entities: [children: leafs],
        schema:
          EntitySchema.widget(
            role: [type: :atom, required: false, default: :content],
            presentation: [type: :atom, required: false, default: :body],
            summary: [type: :string, required: false]
          )
      }

    hero =
      %Spark.Dsl.Entity{
        name: :hero,
        target: Node,
        args: [:id],
        identifier: :id,
        recursive_as: :children,
        auto_set_fields: [family: :foundational, kind: :hero],
        entities: [children: leafs],
        schema:
          EntitySchema.widget(
            eyebrow: [type: :string, required: false],
            title: [type: :string, required: false],
            message: [type: :string, required: false],
            align: [type: :atom, required: false],
            summary: [type: :string, required: false]
          )
      }

    [text, label, icon, image, badge, hero, content, button, link, separator, spacer]
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
      auto_set_fields: [family: :foundational, kind: name],
      schema: EntitySchema.widget(extra_schema)
    }
  end
end
