defmodule UnifiedUi.Widgets do
  @moduledoc """
  Package-facing reference surface for authored widget kinds supported by `UnifiedUi`.
  """

  alias UnifiedUi.Dsl.Entities.{Advanced, Data, Feedback, Foundational, Input, Navigation}
  alias UnifiedUi.Dsl.Entities.WidgetComponents, as: WidgetComponentEntities
  alias UnifiedUi.WidgetComponents

  @spec foundational_kinds() :: [atom()]
  def foundational_kinds do
    Foundational.kinds()
  end

  @spec input_kinds() :: [atom()]
  def input_kinds do
    Input.kinds()
  end

  @spec navigation_kinds() :: [atom()]
  def navigation_kinds do
    Navigation.kinds()
  end

  @spec data_kinds() :: [atom()]
  def data_kinds do
    Data.kinds()
  end

  @spec feedback_kinds() :: [atom()]
  def feedback_kinds do
    Feedback.kinds()
  end

  @spec advanced_kinds() :: [atom()]
  def advanced_kinds do
    Advanced.kinds()
  end

  @spec content_identity_component_kinds() :: [atom()]
  def content_identity_component_kinds do
    WidgetComponentEntities.content_identity_kinds()
  end

  @spec form_control_component_kinds() :: [atom()]
  def form_control_component_kinds do
    WidgetComponentEntities.form_control_kinds()
  end

  @spec navigation_component_kinds() :: [atom()]
  def navigation_component_kinds do
    WidgetComponentEntities.navigation_kinds()
  end

  @spec row_artifact_component_kinds() :: [atom()]
  def row_artifact_component_kinds do
    WidgetComponentEntities.row_artifact_kinds()
  end

  @spec workflow_component_kinds() :: [atom()]
  def workflow_component_kinds do
    WidgetComponentEntities.workflow_kinds()
  end

  @spec layer_callout_component_kinds() :: [atom()]
  def layer_callout_component_kinds do
    WidgetComponentEntities.layer_callout_kinds()
  end

  @spec redline_code_component_kinds() :: [atom()]
  def redline_code_component_kinds do
    WidgetComponentEntities.redline_code_kinds()
  end

  @spec composition_behavior_component_kinds() :: [atom()]
  def composition_behavior_component_kinds do
    WidgetComponentEntities.composition_behavior_kinds()
  end

  @spec component_catalog() :: [WidgetComponents.component()]
  def component_catalog do
    WidgetComponents.catalog()
  end

  @spec component_families() :: %{WidgetComponents.family() => [atom()]}
  def component_families do
    WidgetComponents.component_families()
  end

  @spec component_kinds() :: [atom()]
  def component_kinds do
    WidgetComponents.kinds()
  end

  @spec component_aliases() :: %{atom() => atom()}
  def component_aliases do
    WidgetComponents.aliases()
  end

  @spec kinds() :: [atom()]
  def kinds do
    foundational_kinds() ++
      input_kinds() ++
      navigation_kinds() ++
      data_kinds() ++
      feedback_kinds() ++
      advanced_kinds() ++
      content_identity_component_kinds() ++
      form_control_component_kinds() ++
      navigation_component_kinds() ++
      row_artifact_component_kinds() ++
      workflow_component_kinds() ++
      layer_callout_component_kinds() ++
      redline_code_component_kinds() ++
      composition_behavior_component_kinds()
  end
end
