defmodule UnifiedUi.Dsl.Sections.Composition do
  @moduledoc """
  Baseline authored composition section for `UnifiedUi` modules.
  """

  alias UnifiedUi.Dsl.Entities

  @section %Spark.Dsl.Section{
    name: :composition,
    describe: """
    Declare the baseline authored structure and composition intent for one module.
    """,
    schema: [
      root: [
        type: :atom,
        required: true,
        doc: "Canonical root identity for the authored composition."
      ],
      mode: [
        type: {:in, [:screen, :fragment]},
        required: false,
        default: :screen,
        doc: "Whether the authored module represents a full screen or a fragment."
      ],
      summary: [
        type: :string,
        required: false,
        doc: "Short authored summary of the intended composition."
      ],
      default_slot: [
        type: :atom,
        required: false,
        doc: "Optional default child slot name for later composition entities."
      ]
    ],
    entities: Entities.composition_entities()
  }

  @spec section() :: Spark.Dsl.Section.t()
  def section, do: @section
end
