defmodule UnifiedUi.Dsl.Sections.Signals do
  @moduledoc """
  Baseline authored signal section for `UnifiedUi` modules.
  """

  alias UnifiedUi.Dsl.Entities.Signal

  @section %Spark.Dsl.Section{
    name: :signals,
    describe: """
    Declare baseline authored signal defaults and later interaction-extension hooks.
    """,
    schema: [
      namespace: [
        type: :atom,
        required: false,
        doc: "Optional canonical signal namespace for the authored module."
      ],
      default_target: [
        type: :atom,
        required: false,
        doc: "Optional default target intent or context for authored interactions."
      ],
      mode: [
        type: {:in, [:canonical]},
        required: false,
        default: :canonical,
        doc: "Baseline signal authoring mode for the package."
      ]
    ],
    entities: Signal.entities()
  }

  @spec section() :: Spark.Dsl.Section.t()
  def section, do: @section
end
