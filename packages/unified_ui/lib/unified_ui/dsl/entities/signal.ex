defmodule UnifiedUi.Dsl.Entities.Signal do
  @moduledoc false

  alias UnifiedUi.Signal
  alias UnifiedUi.Binding

  @spec entities() :: [Spark.Dsl.Entity.t()]
  def entities do
    [binding_entity(), interaction_entity()]
  end

  defp binding_entity do
    %Spark.Dsl.Entity{
      name: :data_binding,
      target: Binding,
      identifier: :id,
      schema: [
        id: [type: :atom, required: true],
        path: [type: :any, required: true],
        scope: [type: :any, required: false],
        default: [type: :any, required: false],
        format: [type: :atom, required: false],
        source: [type: :atom, required: false],
        collection?: [type: :boolean, required: false, default: false],
        depends_on: [type: {:list, :any}, required: false, default: []],
        derived: [type: :any, required: false, default: %{}],
        summary: [type: :string, required: false],
        metadata: [type: :keyword_list, required: false, default: []]
      ]
    }
  end

  defp interaction_entity do
    %Spark.Dsl.Entity{
      name: :interaction,
      target: Signal,
      identifier: :id,
      schema: [
        id: [type: :atom, required: true],
        family: [type: {:in, Signal.families()}, required: true],
        intent: [type: :atom, required: false],
        source_context: [type: :keyword_list, required: false, default: []],
        target_intent: [type: :keyword_list, required: false, default: []],
        payload_mapping: [type: :any, required: false, default: %{}],
        binding_refs: [type: {:list, :any}, required: false, default: []],
        summary: [type: :string, required: false],
        metadata: [type: :keyword_list, required: false, default: []]
      ]
    }
  end
end
