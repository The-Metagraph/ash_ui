defmodule UnifiedUi.Dsl.Verifiers do
  @moduledoc """
  Registry of baseline DSL verifiers for authored `UnifiedUi` modules.
  """

  alias UnifiedUi.Dsl.Verifiers.{
    ValidateCompositionPlacement,
    ValidateAuthoringInvariants,
    ValidateRequiredSections,
    ValidateThemesAndSignals,
    ValidateWidgetComponents
  }

  @spec all() :: [module()]
  def all do
    [
      ValidateRequiredSections,
      ValidateAuthoringInvariants,
      ValidateCompositionPlacement,
      ValidateWidgetComponents,
      ValidateThemesAndSignals
    ]
  end
end
