defmodule UnifiedIUR do
  @moduledoc """
  Minimal canonical IUR validation package consumed by Ash UI.

  The package validates the map shape that renderer packages receive.
  """

  @screen_keys ~w(type children bindings metadata)a

  @spec validate(map()) :: :ok | {:error, term()}
  def validate(iur) when is_map(iur) do
    with :ok <- validate_type(iur, "root"),
         :ok <- validate_screen_shape(iur),
         :ok <- validate_children(Map.get(iur, "children", []), "root.children"),
         :ok <- validate_bindings(Map.get(iur, "bindings", []), "root.bindings") do
      :ok
    end
  end

  def validate(other), do: {:error, {:invalid_iur, {:not_a_map, other}}}

  defp validate_screen_shape(%{"type" => "screen"} = iur) do
    missing =
      Enum.reject(@screen_keys, fn key ->
        Map.has_key?(iur, Atom.to_string(key))
      end)

    if missing == [] do
      :ok
    else
      {:error, {:invalid_iur, {:missing_screen_keys, missing}}}
    end
  end

  defp validate_screen_shape(_iur), do: :ok

  defp validate_type(%{"type" => type}, _path) when is_binary(type) and type != "", do: :ok

  defp validate_type(iur, path) do
    {:error, {:invalid_iur, {:missing_type, path, iur}}}
  end

  defp validate_children(children, _path) when children in [nil, []], do: :ok

  defp validate_children(children, path) when is_list(children) do
    Enum.reduce_while(Enum.with_index(children), :ok, fn {child, index}, :ok ->
      child_path = "#{path}[#{index}]"

      case validate_node(child, child_path) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp validate_children(other, path), do: {:error, {:invalid_iur, {:children_not_list, path, other}}}

  defp validate_node(node, path) when is_map(node) do
    with :ok <- validate_type(node, path),
         :ok <- validate_metadata(node, path),
         :ok <- validate_children(Map.get(node, "children", []), "#{path}.children") do
      :ok
    end
  end

  defp validate_node(other, path), do: {:error, {:invalid_iur, {:node_not_map, path, other}}}

  defp validate_metadata(%{"metadata" => metadata}, _path) when is_map(metadata), do: :ok
  defp validate_metadata(%{"metadata" => nil}, _path), do: :ok
  defp validate_metadata(%{"metadata" => metadata}, path), do: {:error, {:invalid_iur, {:metadata_not_map, path, metadata}}}
  defp validate_metadata(_node, _path), do: :ok

  defp validate_bindings(bindings, _path) when bindings in [nil, []], do: :ok

  defp validate_bindings(bindings, path) when is_list(bindings) do
    Enum.reduce_while(Enum.with_index(bindings), :ok, fn {binding, index}, :ok ->
      binding_path = "#{path}[#{index}]"

      cond do
        not is_map(binding) ->
          {:halt, {:error, {:invalid_iur, {:binding_not_map, binding_path, binding}}}}

        not is_binary(Map.get(binding, "type", "")) ->
          {:halt, {:error, {:invalid_iur, {:binding_missing_type, binding_path, binding}}}}

        not is_binary(Map.get(binding, "target", "")) ->
          {:halt, {:error, {:invalid_iur, {:binding_missing_target, binding_path, binding}}}}

        true ->
          {:cont, :ok}
      end
    end)
  end

  defp validate_bindings(other, path), do: {:error, {:invalid_iur, {:bindings_not_list, path, other}}}
end
