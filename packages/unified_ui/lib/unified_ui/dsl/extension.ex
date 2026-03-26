defmodule UnifiedUi.Dsl.Extension do
  @moduledoc """
  Spark extension for authored `UnifiedUi` modules.
  """

  alias UnifiedUi.Dsl.{SectionRegistry, Verifiers}

  use Spark.Dsl.Extension,
    sections: SectionRegistry.sections(),
    verifiers: Verifiers.all(),
    imports: [UnifiedUi.Dsl.Helpers],
    module_prefix: [UnifiedUi, Dsl]
end
