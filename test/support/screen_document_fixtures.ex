defmodule AshUI.Test.ScreenDocumentFixtures do
  @moduledoc false

  alias AshUI.Resource.Authority
  alias AshUI.Test.ResourceAuthorityScreen

  def resource_screen_attrs(name, opts \\ []) do
    layout = Keyword.get(opts, :layout, :row)
    route = Keyword.get(opts, :route)
    metadata = Keyword.get(opts, :metadata, %{})
    binding_metadata = Keyword.get(opts, :binding_metadata, %{})
    active = Keyword.get(opts, :active, true)
    version = Keyword.get(opts, :version, 1)

    {:ok, attrs} =
      Authority.screen_attrs(ResourceAuthorityScreen,
        name: name,
        layout: layout,
        route: route,
        metadata: metadata,
        active: active,
        version: version
      )

    unified_dsl = apply_binding_overrides(attrs.unified_dsl, binding_metadata)
    %{attrs | unified_dsl: unified_dsl}
  end

  def resource_screen_document(name, opts \\ []) do
    resource_screen_attrs(name, opts).unified_dsl
  end

  defp apply_binding_overrides(payload, overrides) when overrides in [%{}, nil], do: payload

  defp apply_binding_overrides(payload, overrides) when is_map(overrides) do
    Enum.reduce(overrides, payload, fn {binding_id, metadata}, acc ->
      binding =
        metadata
        |> Map.new()
        |> Map.put_new("id", to_string(binding_id))
        |> stringify_keys()

      case Map.get(binding, "element_id") do
        nil ->
          update_in(acc, ["screen", "bindings"], fn bindings ->
            upsert_binding(bindings || [], binding)
          end)

        element_id ->
          update_in(acc, ["elements"], fn elements ->
            Enum.map(elements || [], fn element ->
              if element_id_for(element) == to_string(element_id) do
                Map.update(element, "bindings", [binding], &upsert_binding(&1, binding))
              else
                element
              end
            end)
          end)
      end
    end)
  end

  defp upsert_binding(bindings, binding) do
    binding_id = Map.get(binding, "id")

    case Enum.split_with(bindings, &(Map.get(&1, "id") != binding_id)) do
      {kept, []} -> kept ++ [binding]
      {kept, [_existing | rest]} -> kept ++ [binding] ++ rest
    end
  end

  defp element_id_for(element) do
    element["dsl"]
    |> Map.get("metadata", %{})
    |> Map.get("id")
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {key, value} ->
      {to_string(key), if(is_map(value), do: stringify_keys(value), else: value)}
    end)
  end
end
