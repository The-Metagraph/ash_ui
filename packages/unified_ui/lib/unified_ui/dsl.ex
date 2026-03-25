defmodule UnifiedUi.Dsl do
  @moduledoc """
  Spark-backed authored DSL for canonical `UnifiedUi` modules.

  Modules use this DSL to declare canonical UI intent through sectioned authored
  declarations. The authored surface remains renderer-independent and compiles
  into canonical `UnifiedIUR`.
  """

  alias UnifiedUi.Dsl.{Extension, SectionRegistry}

  use Spark.Dsl,
    default_extensions: [extensions: [Extension]]

  @spec section_names() :: [atom()]
  def section_names do
    SectionRegistry.section_names()
  end

  @spec extension_points() :: map()
  def extension_points do
    SectionRegistry.extension_points()
  end

  @spec default_section_options() :: map()
  def default_section_options do
    SectionRegistry.default_section_options()
  end

  @spec module_imports() :: [module()]
  def module_imports do
    Extension.module_imports()
  end
end
