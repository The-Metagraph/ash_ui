defmodule UnifiedUi.Dsl.Entities do
  @moduledoc """
  Baseline registry of canonical authored construct families.
  """

  alias UnifiedUi.Dsl.Entities.{
    Advanced,
    Canvas,
    Data,
    Display,
    Feedback,
    Forms,
    Foundational,
    Input,
    Layout,
    Navigation,
    Overlay,
    WidgetComponents
  }

  @construct_families %{
    widgets: [
      :foundational_visual,
      :input,
      :navigation,
      :feedback,
      :data,
      :operational,
      :content_identity_and_disclosure,
      :form_control_and_composer,
      :row_and_artifact,
      :workflow_progress_and_status,
      :layer_shell_and_callout,
      :redline_and_code,
      :composition_behavior
    ],
    layouts: [:container, :row, :column, :grid, :stack, :split, :viewport],
    layers: [:overlay, :absolute, :modal, :toast, :menu, :canvas],
    styles: [:typography, :color, :spacing, :sizing, :alignment, :border, :visibility],
    themes: [:theme, :variant, :token, :semantic_role],
    signals: [:interaction, :binding, :payload_mapping, :target_intent]
  }

  @spec construct_families() :: %{atom() => [atom()]}
  def construct_families do
    @construct_families
  end

  @spec categories() :: [atom()]
  def categories do
    Map.keys(@construct_families)
  end

  @spec composition_entities() :: [Spark.Dsl.Entity.t()]
  def composition_entities do
    Foundational.entities() ++
      Input.entities() ++
      Navigation.entities() ++
      Forms.top_level_entities() ++
      WidgetComponents.entities() ++
      Layout.entities() ++
      Data.entities() ++
      Feedback.entities() ++
      Advanced.entities() ++
      Overlay.entities() ++
      Display.entities() ++
      Canvas.entities()
  end
end
