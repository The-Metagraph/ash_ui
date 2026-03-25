defmodule UnifiedUi.Dsl.SectionRegistry do
  @moduledoc """
  Registry of the baseline authored DSL sections and extension points.
  """

  alias UnifiedUi.Dsl.Sections

  @sections [
    Sections.Identity.section(),
    Sections.Composition.section(),
    Sections.Themes.section(),
    Sections.Signals.section()
  ]

  @extension_points %{
    identity: [:metadata_fields, :traceability_fields],
    composition: [:widget_entities, :layout_entities, :layer_entities],
    themes: [:theme_entities, :style_entities, :token_entities],
    signals: [:signal_entities, :binding_entities, :payload_entities]
  }

  @default_section_options %{
    identity: %{annotations: %{}, tags: []},
    composition: %{mode: :screen},
    themes: %{inherit?: true},
    signals: %{mode: :canonical}
  }

  @spec sections() :: [Spark.Dsl.Section.t()]
  def sections do
    @sections
  end

  @spec section_names() :: [atom()]
  def section_names do
    Enum.map(@sections, & &1.name)
  end

  @spec extension_points() :: map()
  def extension_points do
    @extension_points
  end

  @spec default_section_options() :: map()
  def default_section_options do
    @default_section_options
  end
end
