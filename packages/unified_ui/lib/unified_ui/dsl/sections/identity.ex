defmodule UnifiedUi.Dsl.Sections.Identity do
  @moduledoc """
  Baseline authored identity and metadata section for `UnifiedUi` modules.
  """

  @section %Spark.Dsl.Section{
    name: :identity,
    describe: """
    Declare the authored module identity, metadata, and traceability baseline.
    """,
    schema: [
      id: [
        type: :atom,
        required: true,
        doc: "Stable authored identifier for the UI module."
      ],
      title: [
        type: :string,
        required: false,
        doc: "Human-readable authored title."
      ],
      description: [
        type: :string,
        required: false,
        doc: "Author-facing description for the authored module."
      ],
      authored_ref: [
        type: {:list, :atom},
        required: false,
        doc: "Optional traceability path for the authored module."
      ],
      annotations: [
        type: :keyword_list,
        required: false,
        default: [],
        doc: "Optional authored annotations."
      ],
      tags: [
        type: {:list, :atom},
        required: false,
        default: [],
        doc: "Optional authored tags."
      ]
    ]
  }

  @spec section() :: Spark.Dsl.Section.t()
  def section, do: @section
end
