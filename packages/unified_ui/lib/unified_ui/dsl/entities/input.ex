defmodule UnifiedUi.Dsl.Entities.Input do
  @moduledoc false

  alias UnifiedUi.Dsl.EntitySchema
  alias UnifiedUi.Dsl.Node

  @spec entities() :: [Spark.Dsl.Entity.t()]
  def entities do
    [
      leaf(:text_input,
        placeholder: [type: :string, required: false],
        value_path: [type: {:list, :atom}, required: false],
        default_value: [type: :string, required: false],
        multiline?: [type: :boolean, required: false, default: false],
        input_mode: [type: :atom, required: false, default: :text]
      ),
      leaf(:numeric_input,
        placeholder: [type: :string, required: false],
        value_path: [type: {:list, :atom}, required: false],
        default_value: [type: :any, required: false],
        min: [type: :any, required: false],
        max: [type: :any, required: false],
        step: [type: :any, required: false]
      ),
      leaf(:toggle,
        label: [type: :string, required: false],
        value_path: [type: {:list, :atom}, required: false],
        default_value: [type: :boolean, required: false]
      ),
      leaf(:checkbox,
        label: [type: :string, required: false],
        value_path: [type: {:list, :atom}, required: false],
        default_value: [type: :boolean, required: false]
      ),
      leaf(:radio_group,
        label: [type: :string, required: false],
        options: [type: :keyword_list, required: true],
        value_path: [type: {:list, :atom}, required: false],
        default_value: [type: :any, required: false]
      ),
      leaf(:select,
        label: [type: :string, required: false],
        options: [type: :keyword_list, required: true],
        value_path: [type: {:list, :atom}, required: false],
        default_value: [type: :atom, required: false],
        multiple?: [type: :boolean, required: false, default: false]
      ),
      leaf(:pick_list,
        label: [type: :string, required: false],
        options: [type: :keyword_list, required: true],
        value_path: [type: {:list, :atom}, required: false],
        default_value: [type: :any, required: false],
        multiple?: [type: :boolean, required: false, default: true]
      ),
      leaf(:date_input,
        value_path: [type: {:list, :atom}, required: false],
        default_value: [type: :any, required: false],
        format: [type: :atom, required: false, default: :iso8601],
        min: [type: :any, required: false],
        max: [type: :any, required: false]
      ),
      leaf(:time_input,
        value_path: [type: {:list, :atom}, required: false],
        default_value: [type: :any, required: false],
        format: [type: :atom, required: false, default: :iso8601],
        min: [type: :any, required: false],
        max: [type: :any, required: false],
        step: [type: :any, required: false]
      ),
      leaf(:file_input,
        label: [type: :string, required: false],
        value_path: [type: {:list, :atom}, required: false],
        accept: [type: {:list, :string}, required: false],
        multiple?: [type: :boolean, required: false, default: false],
        capture: [type: :string, required: false]
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
      auto_set_fields: [family: :input, kind: name],
      schema: EntitySchema.widget(extra_schema)
    }
  end
end
