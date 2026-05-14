defmodule LiveUi.Examples do
  @moduledoc """
  Maintained aligned example inventory for `live_ui`.
  """

  alias LiveUi.Examples.Aligned

  @spec catalog() :: [map()]
  def catalog do
    aligned_catalog()
  end

  @spec aligned_example_ids() :: [atom()]
  def aligned_example_ids do
    Aligned.ids()
  end

  @spec aligned_modules() :: [module()]
  def aligned_modules do
    Aligned.modules()
  end

  @spec aligned_catalog() :: [map()]
  def aligned_catalog do
    Aligned.catalog()
  end

  @spec repository_example_ids() :: [atom()]
  def repository_example_ids do
    Aligned.repository_example_ids()
  end

  @spec find(atom() | String.t()) :: {:ok, map()} | :error
  def find(id) when is_atom(id) or is_binary(id) do
    Aligned.find(id)
  end

  @spec find_aligned(atom() | String.t()) :: {:ok, map()} | :error
  def find_aligned(id) when is_atom(id) or is_binary(id) do
    find(id)
  end

  @spec canonical_review_supported?(atom() | String.t()) :: boolean()
  def canonical_review_supported?(id) do
    Aligned.canonical_review_supported?(id)
  end

  @spec canonical_review_ids() :: [atom()]
  def canonical_review_ids do
    Aligned.canonical_review_ids()
  end

  @spec canonical_element(atom() | String.t()) :: {:ok, UnifiedIUR.Element.t()} | {:error, term()}
  def canonical_element(id) do
    Aligned.canonical_element(id)
  end

  @spec canonical_metadata(atom() | String.t()) :: {:ok, map()} | {:error, term()}
  def canonical_metadata(id) do
    Aligned.canonical_metadata(id)
  end
end
