defmodule AshUI.Runtime.Navigation do
  @moduledoc """
  Runtime bridge for canonical navigation interactions.

  Resource-authored navigation remains symbolic in canonical IUR. This module
  validates the transport descriptor, resolves symbolic targets against the
  host-provided Ash UI graph, and records the pending navigation command at the
  runtime boundary.
  """

  alias AshUI.Rendering.CanonicalIUR
  alias UnifiedIUR.{Element, Interaction}
  alias UnifiedIUR.Interactions.Transport

  @history_actions [:go_back, "go_back", :go_forward, "go_forward", :close_modal, "close_modal"]

  @type resolution :: %{
          action: atom() | String.t(),
          target: term(),
          params: map(),
          metadata: map()
        }

  @doc """
  Returns canonical navigation interactions carried by a root element.
  """
  @spec interactions(Element.t() | map()) :: [Interaction.t()]
  def interactions(root), do: CanonicalIUR.navigation_interactions(root)

  @doc """
  Finds a canonical navigation interaction by action id, element id, and signal.
  """
  @spec find_interaction(Element.t() | map(), term(), term(), term()) ::
          {:ok, CanonicalIUR.interaction_entry()} | {:error, :navigation_interaction_not_found}
  def find_interaction(root, action_id, element_id \\ nil, signal \\ nil) do
    root
    |> CanonicalIUR.interaction_entries()
    |> Enum.filter(&CanonicalIUR.navigation_interaction?(&1.interaction))
    |> Enum.find(fn entry ->
      action_id_matches?(entry.interaction, action_id) and
        element_id_matches?(entry, element_id) and
        signal_matches?(entry.interaction, signal)
    end)
    |> case do
      nil -> {:error, :navigation_interaction_not_found}
      entry -> {:ok, entry}
    end
  end

  @doc """
  Validates and resolves a canonical navigation interaction.
  """
  @spec execute(Interaction.t() | map(), map()) :: {:ok, map()} | {:error, term()}
  def execute(interaction, context \\ %{}) do
    interaction = Interaction.new(interaction)
    descriptor = Transport.boundary_descriptor(interaction)

    with :ok <- Transport.validate_boundary_descriptor(descriptor),
         {:ok, resolution} <- resolve_descriptor(descriptor, context) do
      {:ok,
       %{
         status: :ok,
         descriptor: descriptor,
         resolution: resolution,
         transport_summary: Transport.summarize_boundary_descriptor(descriptor)
       }}
    end
  end

  @doc """
  Handles a LiveView action event as canonical navigation.
  """
  @spec handle_event(map(), Phoenix.LiveView.Socket.t()) ::
          {:ok, map(), Phoenix.LiveView.Socket.t()} | {:error, term()}
  def handle_event(event_params, socket) when is_map(event_params) do
    root = Map.get(socket.assigns, :ash_ui_base_iur)
    action_id = Map.get(event_params, "action_id") || Map.get(event_params, :action_id)
    element_id = Map.get(event_params, "element_id") || Map.get(event_params, :element_id)
    signal = Map.get(event_params, "signal") || Map.get(event_params, :signal)

    with {:ok, entry} <- find_interaction(root, action_id, element_id, signal),
         {:ok, result} <- execute(entry.interaction, runtime_context(socket)) do
      {:ok, result, assign_navigation(socket, result)}
    end
  end

  @doc """
  Resolves a canonical boundary descriptor against a runtime context.
  """
  @spec resolve_descriptor(map(), map()) :: {:ok, resolution()} | {:error, term()}
  def resolve_descriptor(descriptor, context \\ %{}) when is_map(descriptor) do
    navigation =
      descriptor
      |> get_in([:target, :navigation])
      |> normalize_map()

    action = value(navigation, :action)

    cond do
      action in [:navigate_to, "navigate_to", :replace_with, "replace_with"] ->
        resolve_named_target(:screen, value(navigation, :screen), navigation, context)

      action in [:open_modal, "open_modal"] ->
        resolve_named_target(:modal, value(navigation, :modal), navigation, context)

      action in @history_actions ->
        {:ok, build_resolution(action, :host_runtime, navigation)}

      true ->
        {:error, {:unsupported_navigation_action, action}}
    end
  end

  defp resolve_named_target(type, target, navigation, context) do
    case find_target(type, target, context) do
      nil -> {:error, {:unresolved_navigation_target, type, target}}
      resolved -> {:ok, build_resolution(value(navigation, :action), resolved, navigation)}
    end
  end

  defp build_resolution(action, target, navigation) do
    %{
      action: action,
      target: target,
      params: normalize_map(value(navigation, :params)),
      metadata: normalize_map(value(navigation, :metadata)),
      modal_stack: normalize_map(value(navigation, :modal_stack))
    }
  end

  defp find_target(:screen, target, context) do
    context
    |> target_candidates([:screens, :ash_ui_screens, "screens"])
    |> include_current_screen(context)
    |> Enum.find(&target_matches?(&1, target))
  end

  defp find_target(:modal, target, context) do
    context
    |> target_candidates([:modals, :ash_ui_modals, "modals", :screens, "screens"])
    |> Enum.find(&target_matches?(&1, target))
  end

  defp target_candidates(context, keys) do
    graph = value(context, :navigation_graph) || value(context, :ash_ui_navigation_graph) || %{}

    keys
    |> Enum.flat_map(fn key ->
      List.wrap(value(context, key)) ++ List.wrap(value(graph, key))
    end)
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
  end

  defp include_current_screen(candidates, context) do
    case value(context, :ash_ui_screen) do
      nil -> candidates
      screen -> [screen | candidates]
    end
  end

  defp target_matches?(_target, nil), do: false

  defp target_matches?(target, expected) when is_map(target) do
    expected_string = to_string(expected)

    [:name, "name", :id, "id", :screen, "screen", :modal, "modal"]
    |> Enum.any?(fn key ->
      case Map.get(target, key) do
        nil -> false
        value -> to_string(value) == expected_string
      end
    end)
  end

  defp target_matches?(target, expected), do: to_string(target) == to_string(expected)

  defp runtime_context(socket) do
    assigns = socket.assigns

    %{
      ash_ui_screen: Map.get(assigns, :ash_ui_screen),
      ash_ui_navigation_graph: Map.get(assigns, :ash_ui_navigation_graph),
      ash_ui_screens: Map.get(assigns, :ash_ui_screens),
      ash_ui_modals: Map.get(assigns, :ash_ui_modals),
      params: Map.get(assigns, :ash_ui_params, %{}),
      assigns: assigns
    }
  end

  defp assign_navigation(socket, result) do
    history = [result | Map.get(socket.assigns, :ash_ui_navigation_history, [])]

    socket
    |> Phoenix.Component.assign(:ash_ui_navigation, result)
    |> Phoenix.Component.assign(:ash_ui_navigation_history, history)
  end

  defp action_id_matches?(_interaction, nil), do: false

  defp action_id_matches?(%Interaction{} = interaction, action_id) do
    [value(interaction.source, :action_id), interaction.intent]
    |> Enum.reject(&is_nil/1)
    |> Enum.any?(&(to_string(&1) == to_string(action_id)))
  end

  defp element_id_matches?(_entry, nil), do: true

  defp element_id_matches?(entry, element_id) do
    to_string(entry.element_id) == to_string(element_id) or
      to_string(value(entry.interaction.source, :element_id)) == to_string(element_id)
  end

  defp signal_matches?(_interaction, nil), do: true

  defp signal_matches?(%Interaction{} = interaction, signal) do
    case value(interaction.source, :trigger) do
      nil -> true
      trigger -> to_string(trigger) == to_string(signal)
    end
  end

  defp normalize_map(value) when is_map(value), do: Map.new(value)
  defp normalize_map(value) when is_list(value), do: Enum.into(value, %{})
  defp normalize_map(_value), do: %{}

  defp value(map, key) when is_map(map), do: Map.get(map, key) || Map.get(map, to_string(key))
  defp value(_value, _key), do: nil
end
