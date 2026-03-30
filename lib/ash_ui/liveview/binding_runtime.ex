defmodule AshUI.LiveView.BindingRuntime do
  @moduledoc """
  Shared runtime helpers for binding ownership, partitioning, and hydration.

  Phase 15 realigns the runtime around resource-local ownership, so bindings are
  no longer treated as one undifferentiated screen document blob. This module
  keeps the partitioned binding state consistent across mount, updates, and
  event handling.
  """

  alias AshUI.LiveView.IURHydration

  @type binding_state :: map()
  @type binding_map :: %{optional(String.t() | atom()) => binding_state()}
  @type partitions :: %{
          all: binding_map(),
          screen: binding_map(),
          elements: binding_map(),
          actions: binding_map()
        }

  @doc """
  Assigns the current binding state maps and refreshes the hydrated IUR view.
  """
  @spec assign(Phoenix.LiveView.Socket.t(), binding_map()) :: Phoenix.LiveView.Socket.t()
  def assign(socket, bindings) when is_map(bindings) do
    partitions = partition(bindings)
    ash_ui = Map.get(socket.assigns, :ash_ui, %{})

    runtime_assigns =
      ash_ui
      |> Map.put(:bindings, runtime_binding_values(partitions))
      |> Map.put(:screen_bindings, runtime_screen_values(partitions.screen))

    socket
    |> Phoenix.Component.assign(:ash_ui_bindings, partitions.all)
    |> Phoenix.Component.assign(:ash_ui_screen_bindings, partitions.screen)
    |> Phoenix.Component.assign(:ash_ui_element_bindings, partitions.elements)
    |> Phoenix.Component.assign(:ash_ui_action_bindings, partitions.actions)
    |> Phoenix.Component.assign(:ash_ui, runtime_assigns)
    |> sync_hydrated_iur(partitions)
  end

  @doc """
  Merges updated binding states into the current runtime binding map.
  """
  @spec merge(Phoenix.LiveView.Socket.t(), binding_map()) :: Phoenix.LiveView.Socket.t()
  def merge(socket, updated_bindings) when is_map(updated_bindings) do
    current_bindings = Map.get(socket.assigns, :ash_ui_bindings, %{})
    assign(socket, Map.merge(current_bindings, updated_bindings))
  end

  @doc """
  Partitions bindings into screen, element, and action ownership groups.
  """
  @spec partition(binding_map()) :: partitions()
  def partition(bindings) when is_map(bindings) do
    Enum.reduce(bindings, %{all: bindings, screen: %{}, elements: %{}, actions: %{}}, fn
      {binding_id, binding_state}, acc when is_map(binding_state) ->
        case partition_key(binding_state) do
          :screen -> put_partition(acc, :screen, binding_id, binding_state)
          :action -> put_partition(acc, :actions, binding_id, binding_state)
          :element -> put_partition(acc, :elements, binding_id, binding_state)
        end

      _entry, acc ->
        acc
    end)
  end

  def partition(_other), do: %{all: %{}, screen: %{}, elements: %{}, actions: %{}}

  @doc """
  Returns true when the given binding state represents an action binding.
  """
  @spec action_binding?(binding_state()) :: boolean()
  def action_binding?(binding_state) when is_map(binding_state) do
    case Map.get(binding_state, :binding_type) || Map.get(binding_state, "binding_type") do
      value when value in [:action, "action", "event"] ->
        true

      _ ->
        source = Map.get(binding_state, :source) || Map.get(binding_state, "source") || %{}
        not is_nil(Map.get(source, :action) || Map.get(source, "action"))
    end
  end

  @doc """
  Returns the owning scope for the binding state.
  """
  @spec owner_scope(binding_state()) :: :screen | :element
  def owner_scope(binding_state) when is_map(binding_state) do
    case owner_metadata(binding_state, "owner_scope") do
      value when value in [:screen, "screen"] -> :screen
      _ -> :element
    end
  end

  @doc """
  Returns the owning element identifier when the binding is element-scoped.
  """
  @spec owner_element_id(binding_state()) :: String.t() | nil
  def owner_element_id(binding_state) when is_map(binding_state) do
    owner_metadata(binding_state, "owner_element_id") ||
      Map.get(binding_state, :element_id) ||
      Map.get(binding_state, "element_id")
  end

  @doc """
  Returns the declared owner signal for action bindings when present.
  """
  @spec owner_signal(binding_state()) :: String.t() | nil
  def owner_signal(binding_state) when is_map(binding_state) do
    case owner_metadata(binding_state, "owner_signal") do
      nil -> nil
      value -> to_string(value)
    end
  end

  defp partition_key(binding_state) do
    cond do
      action_binding?(binding_state) -> :action
      owner_scope(binding_state) == :screen -> :screen
      true -> :element
    end
  end

  defp put_partition(acc, partition, binding_id, binding_state) do
    Map.update!(acc, partition, &Map.put(&1, binding_id, binding_state))
  end

  defp owner_metadata(binding_state, key) do
    metadata = Map.get(binding_state, :metadata) || Map.get(binding_state, "metadata") || %{}

    atom_key =
      try do
        String.to_existing_atom(key)
      rescue
        ArgumentError -> nil
      end

    Map.get(metadata, key) || if(atom_key, do: Map.get(metadata, atom_key))
  end

  defp runtime_binding_values(partitions) do
    partitions
    |> Map.fetch!(:all)
    |> Enum.reduce(%{}, fn {_binding_id, binding_state}, acc ->
      case Map.get(binding_state, :target) || Map.get(binding_state, "target") do
        nil ->
          acc

        target ->
          Map.put(acc, target, %{
            "value" => Map.get(binding_state, :value) || Map.get(binding_state, "value"),
            "error" => Map.get(binding_state, :error) || Map.get(binding_state, "error"),
            "updated_at" =>
              Map.get(binding_state, :updated_at) || Map.get(binding_state, "updated_at")
          })
      end
    end)
  end

  defp runtime_screen_values(screen_bindings) do
    Enum.reduce(screen_bindings, %{}, fn {_binding_id, binding_state}, acc ->
      case Map.get(binding_state, :target) || Map.get(binding_state, "target") do
        nil ->
          acc

        target ->
          Map.put(acc, target, %{
            "value" => Map.get(binding_state, :value) || Map.get(binding_state, "value"),
            "error" => Map.get(binding_state, :error) || Map.get(binding_state, "error"),
            "updated_at" =>
              Map.get(binding_state, :updated_at) || Map.get(binding_state, "updated_at")
          })
      end
    end)
  end

  defp sync_hydrated_iur(socket, partitions) do
    case Map.get(socket.assigns, :ash_ui_base_iur) || Map.get(socket.assigns, :ash_ui_iur) do
      %{} = iur ->
        Phoenix.Component.assign(socket, :ash_ui_iur, IURHydration.hydrate(iur, partitions.all))

      _ ->
        socket
    end
  end
end
