defmodule UnifiedUi.Dsl.Identity do
  @moduledoc """
  Baseline identity and traceability rules for authored `UnifiedUi` modules.
  """

  alias Spark.Dsl.Extension

  @required_sections [:identity, :composition]
  @reserved_ids [:identity, :composition, :themes, :signals, :root]
  @traceability_fields [:authored_ref, :annotations, :tags]
  @identifier_fields %{
    identity: :id,
    composition: :root,
    themes: :default_theme,
    signals: :namespace
  }

  @spec required_sections() :: [atom()]
  def required_sections do
    @required_sections
  end

  @spec reserved_ids() :: [atom()]
  def reserved_ids do
    @reserved_ids
  end

  @spec traceability_fields() :: [atom()]
  def traceability_fields do
    @traceability_fields
  end

  @spec identifier_fields() :: %{atom() => atom()}
  def identifier_fields do
    @identifier_fields
  end

  @spec module_identity(module()) :: map()
  def module_identity(module) when is_atom(module) do
    %{
      id: Extension.get_opt(module, [:identity], :id, nil),
      title: Extension.get_opt(module, [:identity], :title, nil),
      description: Extension.get_opt(module, [:identity], :description, nil),
      authored_ref: Extension.get_opt(module, [:identity], :authored_ref, []),
      annotations: Extension.get_opt(module, [:identity], :annotations, []),
      tags: Extension.get_opt(module, [:identity], :tags, [])
    }
  end
end
