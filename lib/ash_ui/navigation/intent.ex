defmodule AshUI.Navigation.Intent do
  @moduledoc """
  Host-independent navigation intent helpers for Ash UI resources.

  Navigation intent stays symbolic until a runtime adapter resolves it against
  the Ash UI application graph.
  """

  @forbidden_fields UnifiedIUR.Interactions.Transport.forbidden_navigation_keys()

  @doc """
  Returns the canonical navigation actions supported by the current Unified UI package set.
  """
  @spec actions() :: [atom()]
  def actions do
    UnifiedUi.Signal.navigation_actions()
  end

  @doc """
  Returns fields that may not appear in resource-authored navigation declarations.
  """
  @spec forbidden_fields() :: [atom()]
  def forbidden_fields, do: @forbidden_fields

  @doc """
  Normalizes and validates a resource-authored navigation target intent.
  """
  @spec normalize!(map() | keyword(), keyword()) :: map()
  def normalize!(intent, opts \\ [])

  def normalize!(intent, opts) when is_map(intent) or is_list(intent) do
    label = Keyword.get(opts, :label, "navigation")

    intent
    |> normalize_map()
    |> reject_forbidden_fields!(label)
    |> validate_supported_shape!(label)
  end

  def normalize!(intent, opts) do
    label = Keyword.get(opts, :label, "navigation")
    raise ArgumentError, "#{label} must be a map or keyword list, got: #{inspect(intent)}"
  end

  @doc """
  Converts a target intent into the canonical descriptor used by Unified UI.
  """
  @spec descriptor!(map() | keyword(), keyword()) :: map()
  def descriptor!(intent, opts \\ []) do
    intent = normalize!(intent, opts)

    UnifiedUi.Signal.navigation_descriptor(%{
      family: :navigation,
      target_intent: intent
    })
  end

  defp validate_supported_shape!(intent, label) do
    action = fetch(intent, :action)

    cond do
      is_nil(action) ->
        validate_local_destination!(intent, label)

      action in actions() ->
        validate_action_contract!(intent, action, label)

      true ->
        raise ArgumentError,
              "#{label} action must be one of #{inspect(actions())}, got: #{inspect(action)}"
    end
  end

  defp validate_local_destination!(intent, label) do
    binding = fetch(intent, :binding)
    destination = fetch(intent, :destination)

    if present_symbolic?(binding) and present_symbolic?(destination) do
      intent
    else
      raise ArgumentError,
            "#{label} without an action must declare symbolic :binding and :destination fields"
    end
  end

  defp validate_action_contract!(intent, action, label) do
    contract = UnifiedUi.Signal.navigation_action_contracts()[action]

    Enum.each(contract.required_fields, fn field ->
      unless present_symbolic?(fetch(intent, field)) do
        raise ArgumentError,
              "#{label} action #{inspect(action)} requires symbolic #{inspect(field)}"
      end
    end)

    validate_optional_maps!(intent, label)
    intent
  end

  defp validate_optional_maps!(intent, label) do
    Enum.each([:params, :metadata], fn key ->
      value = fetch(intent, key)

      unless is_nil(value) or is_map(value) do
        raise ArgumentError, "#{label} #{inspect(key)} must be a map when present"
      end
    end)
  end

  defp reject_forbidden_fields!(intent, label) do
    case forbidden_field_path(intent) do
      nil ->
        intent

      path ->
        raise ArgumentError,
              "#{label} may not include host/runtime navigation field #{inspect(Enum.join(path, "."))}"
    end
  end

  defp forbidden_field_path(value, path \\ [])

  defp forbidden_field_path(map, path) when is_map(map) do
    Enum.find_value(map, fn {key, value} ->
      normalized_key = normalize_key(key)

      cond do
        normalized_key in @forbidden_fields ->
          path ++ [normalized_key]

        is_map(value) ->
          forbidden_field_path(value, path ++ [normalized_key])

        is_list(value) ->
          forbidden_field_path(value, path ++ [normalized_key])

        true ->
          nil
      end
    end)
  end

  defp forbidden_field_path(list, path) when is_list(list) do
    list
    |> Enum.with_index()
    |> Enum.find_value(fn {value, index} ->
      if is_map(value) or is_list(value) do
        forbidden_field_path(value, path ++ [index])
      end
    end)
  end

  defp forbidden_field_path(_value, _path), do: nil

  defp normalize_map(values) when is_list(values), do: values |> Enum.into(%{}) |> normalize_map()

  defp normalize_map(values) when is_map(values) do
    values
    |> Map.new(fn {key, value} ->
      {normalize_key(key), normalize_value(value)}
    end)
  end

  defp normalize_value(value) when is_list(value) do
    if Keyword.keyword?(value),
      do: normalize_map(value),
      else: Enum.map(value, &normalize_value/1)
  end

  defp normalize_value(value) when is_map(value), do: normalize_map(value)
  defp normalize_value(value), do: value

  defp normalize_key(key) when is_atom(key), do: key

  defp normalize_key(key) when is_binary(key) do
    try do
      String.to_existing_atom(key)
    rescue
      ArgumentError -> key
    end
  end

  defp normalize_key(key), do: key

  defp fetch(map, key), do: Map.get(map, key, Map.get(map, to_string(key)))

  defp present_symbolic?(value) when is_atom(value), do: not is_nil(value)
  defp present_symbolic?(value) when is_binary(value), do: String.trim(value) != ""
  defp present_symbolic?(_value), do: false
end
