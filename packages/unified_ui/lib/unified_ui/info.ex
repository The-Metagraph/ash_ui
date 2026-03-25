defmodule UnifiedUi.Info do
  @moduledoc """
  Package-facing authored module introspection helpers.
  """

  alias Spark.Dsl.Extension
  alias UnifiedUi.Dsl.Node
  alias UnifiedUi.Examples
  alias UnifiedUi.Reference
  alias UnifiedUi.Signals
  alias UnifiedUi.Theme

  @spec supported_construct_families() :: %{atom() => [atom()]}
  def supported_construct_families do
    Reference.construct_families()
  end

  @spec supported_compiled_construct_families() :: map()
  def supported_compiled_construct_families do
    Reference.compiled_construct_families()
  end

  @spec style_attribute_families() :: %{atom() => [atom()]}
  def style_attribute_families do
    Reference.style_attribute_families()
  end

  @spec composition_nodes(module()) :: [struct()]
  def composition_nodes(module) when is_atom(module) do
    Extension.get_entities(module, [:composition])
  end

  @spec composition_summary(module()) :: [map()]
  def composition_summary(module) when is_atom(module) do
    module
    |> composition_nodes()
    |> Enum.map(&Node.summary/1)
  end

  @spec example_summaries() :: [map()]
  def example_summaries do
    Examples.catalog()
    |> Enum.map(fn example ->
      Map.put(example, :composition, composition_summary(example.module))
    end)
  end

  @spec module_summary(module()) :: map()
  def module_summary(module) when is_atom(module) do
    %{
      module: module,
      sections: section_usage(module),
      identifiers: declared_identifiers(module),
      identity: section_options(module, :identity),
      composition: section_options(module, :composition),
      themes: section_options(module, :themes),
      signals: section_options(module, :signals),
      theme_catalog: Theme.module_summary(module),
      signal_catalog: Signals.module_summary(module),
      validation_state: validation_state(module)
    }
  end

  @spec inspect_module(module()) :: map()
  def inspect_module(module) when is_atom(module) do
    module_summary(module)
  end

  @spec section_usage(module()) :: %{atom() => boolean()}
  def section_usage(module) when is_atom(module) do
    Reference.dsl_sections()
    |> Map.new(fn {section, metadata} ->
      {section, section_present?(module, section, metadata.fields)}
    end)
  end

  @spec declared_identifiers(module()) :: map()
  def declared_identifiers(module) when is_atom(module) do
    %{
      module_id: Extension.get_opt(module, [:identity], :id, nil),
      root_id: Extension.get_opt(module, [:composition], :root, nil),
      default_theme: Extension.get_opt(module, [:themes], :default_theme, nil),
      signal_namespace: Extension.get_opt(module, [:signals], :namespace, nil)
    }
  end

  @spec validation_state(module()) :: :phase_1_valid | :invalid
  def validation_state(module) when is_atom(module) do
    identifiers = declared_identifiers(module)
    sections = section_usage(module)
    root = identifiers.root_id
    module_id = identifiers.module_id
    slot = Extension.get_opt(module, [:composition], :default_slot, nil)
    mode = Extension.get_opt(module, [:composition], :mode, :screen)

    if sections.identity and sections.composition and
         not is_nil(module_id) and
         not is_nil(root) and
         module_id != root and
         (is_nil(slot) or mode == :fragment) do
      :phase_1_valid
    else
      :invalid
    end
  end

  defp section_options(module, section) do
    fields = Reference.dsl_sections() |> Map.fetch!(section) |> Map.fetch!(:fields)

    fields
    |> Enum.map(fn field -> {field, Extension.get_opt(module, [section], field, nil)} end)
    |> Enum.reject(fn {_field, value} -> is_nil(value) end)
    |> Enum.into(%{})
  end

  defp section_present?(module, section, fields) do
    Enum.any?(fields, fn field ->
      not is_nil(Extension.get_opt(module, [section], field, nil))
    end)
  end
end
