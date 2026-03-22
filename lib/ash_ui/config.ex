defmodule AshUI.Config do
  @moduledoc """
  Central configuration resolver for Ash UI.

  This module separates the configurable UI storage boundary from the runtime
  `:ash_domains` used by bindings to resolve application resources.
  """

  @default_ui_storage [
    domain: AshUI.Domain,
    resources: [
      screen: AshUI.Resources.Screen,
      element: AshUI.Resources.Element,
      binding: AshUI.Resources.Binding
    ],
    repo: AshUI.Repo
  ]

  @type ui_storage :: [
          domain: module(),
          resources: [screen: module(), element: module(), binding: module()],
          repo: module() | nil
        ]

  @doc """
  Returns the effective UI storage configuration.

  The default shipped configuration is merged with application config and any
  optional override payload passed in.
  """
  @spec ui_storage(keyword() | map() | nil) :: ui_storage()
  def ui_storage(overrides \\ nil) do
    @default_ui_storage
    |> merge_storage(normalize_ui_storage(Application.get_env(:ash_ui, :ui_storage, [])))
    |> merge_storage(normalize_ui_storage(overrides))
  end

  @doc """
  Returns the configured UI storage domain.
  """
  @spec ui_storage_domain(keyword() | map() | nil) :: module()
  def ui_storage_domain(overrides \\ nil) do
    ui_storage(overrides)
    |> Keyword.fetch!(:domain)
  end

  @doc """
  Returns the configured screen resource.
  """
  @spec screen_resource(keyword() | map() | nil) :: module()
  def screen_resource(overrides \\ nil) do
    ui_storage(overrides)
    |> Keyword.fetch!(:resources)
    |> Keyword.fetch!(:screen)
  end

  @doc """
  Returns the configured element resource.
  """
  @spec element_resource(keyword() | map() | nil) :: module()
  def element_resource(overrides \\ nil) do
    ui_storage(overrides)
    |> Keyword.fetch!(:resources)
    |> Keyword.fetch!(:element)
  end

  @doc """
  Returns the configured binding resource.
  """
  @spec binding_resource(keyword() | map() | nil) :: module()
  def binding_resource(overrides \\ nil) do
    ui_storage(overrides)
    |> Keyword.fetch!(:resources)
    |> Keyword.fetch!(:binding)
  end

  @doc """
  Returns the configured repo child for UI storage, if any.
  """
  @spec ui_storage_repo(keyword() | map() | nil) :: module() | nil
  def ui_storage_repo(overrides \\ nil) do
    ui_storage(overrides)
    |> Keyword.get(:repo)
  end

  @doc """
  Returns the configured runtime resource domains used by bindings.
  """
  @spec runtime_domains(keyword() | map() | nil) :: [module()]
  def runtime_domains(overrides \\ nil) do
    overrides
    |> extract_runtime_domains()
    |> case do
      nil ->
        Application.get_env(:ash_ui, :ash_domains, [ui_storage_domain(overrides)])

      domains ->
        domains
    end
    |> List.wrap()
    |> Enum.uniq()
  end

  @doc """
  Returns true when the given record matches the configured screen resource.
  """
  @spec screen_record?(term(), keyword() | map() | nil) :: boolean()
  def screen_record?(record, overrides \\ nil)

  def screen_record?(%{__struct__: module}, overrides) do
    module == screen_resource(overrides)
  end

  def screen_record?(_record, _overrides), do: false

  defp normalize_ui_storage(nil), do: []

  defp normalize_ui_storage(%{ui_storage: storage}) do
    normalize_ui_storage(storage)
  end

  defp normalize_ui_storage(overrides) when is_list(overrides) do
    cond do
      not Keyword.keyword?(overrides) ->
        []

      Keyword.has_key?(overrides, :ui_storage) ->
        normalize_ui_storage(Keyword.get(overrides, :ui_storage))

      true ->
        normalize_storage_keyword(overrides)
    end
  end

  defp normalize_ui_storage(%{} = overrides) do
    overrides
    |> Enum.into([])
    |> normalize_storage_keyword()
  end

  defp normalize_ui_storage(_other), do: []

  defp normalize_storage_keyword(storage) do
    resources =
      storage
      |> Keyword.get(:resources, [])
      |> normalize_resources()

    storage
    |> Keyword.delete(:resources)
    |> Keyword.put(:resources, resources)
  end

  defp normalize_resources(nil), do: []

  defp normalize_resources(resources) when is_list(resources) do
    if Keyword.keyword?(resources) do
      resources
    else
      []
    end
  end

  defp normalize_resources(%{} = resources), do: Enum.into(resources, [])
  defp normalize_resources(_other), do: []

  defp merge_storage(base, overrides) do
    base_resources = Keyword.get(base, :resources, [])
    override_resources = Keyword.get(overrides, :resources, [])

    base
    |> Keyword.merge(overrides)
    |> Keyword.put(:resources, Keyword.merge(base_resources, override_resources))
  end

  defp extract_runtime_domains(nil), do: nil

  defp extract_runtime_domains(%{ash_domains: domains}) do
    domains
  end

  defp extract_runtime_domains(overrides) when is_list(overrides) do
    if Keyword.keyword?(overrides) do
      Keyword.get(overrides, :ash_domains)
    else
      nil
    end
  end

  defp extract_runtime_domains(_other), do: nil
end
