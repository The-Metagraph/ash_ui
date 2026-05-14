defmodule LiveUi.Runtime.Navigation do
  @moduledoc """
  Server-authoritative canonical navigation transition handling for `live_ui`.
  """

  alias LiveUi.Runtime.{CanonicalScreen, Error, State}
  alias UnifiedIUR.Element
  alias UnifiedIUR.Interaction
  alias UnifiedIUR.Interactions.Transport, as: BoundaryTransport

  @managed_assign_keys [
    :current_screen_id,
    :current_screen_title,
    :navigation_action,
    :navigation_params,
    :navigation_history,
    :navigation_forward,
    :navigation_modal_stack,
    :current_modal,
    :navigation_host_route
  ]

  @type screen_ref :: module() | Element.t()
  @type route_resolver :: (map(), State.t() -> {:ok, term()} | {:error, term()} | term())
  @type host_route_resolver :: (map(), State.t() ->
                                  map() | nil | {:ok, map() | nil} | {:error, term()})

  @type entry :: %{
          screen_id: atom() | String.t(),
          title: String.t(),
          mode: State.mode(),
          screen_ref: screen_ref(),
          params: map(),
          metadata: map(),
          host_route: map() | nil
        }

  @type t :: %{
          registry: map(),
          resolver: route_resolver() | nil,
          host_route_resolver: host_route_resolver() | nil,
          active: entry(),
          history: [entry()],
          forward: [entry()],
          modals: [map()],
          last_transition: map() | nil,
          last_host_route: map() | nil
        }

  @spec initialize(module(), map(), State.mode(), keyword()) :: t()
  def initialize(screen, assigns, mode, opts) when is_atom(screen) and is_map(assigns) do
    active = current_entry(screen, assigns, mode, opts)

    %{
      registry: Keyword.get(opts, :screen_registry, %{}),
      resolver: Keyword.get(opts, :navigation_resolver),
      host_route_resolver: Keyword.get(opts, :host_route_resolver),
      active: active,
      history: [],
      forward: [],
      modals: [],
      last_transition: nil,
      last_host_route: nil
    }
  end

  @spec transition?(map()) :: boolean()
  def transition?(%{family: :navigation, target: target}) when is_map(target) do
    not is_nil(raw_navigation_descriptor(target))
  end

  def transition?(_other), do: false

  @spec apply_transition(State.t(), map()) :: {:ok, State.t()} | {:error, Error.t()}
  def apply_transition(%State{} = state, runtime_action) when is_map(runtime_action) do
    with {:ok, descriptor} <- navigation_descriptor(runtime_action),
         :ok <- validate_runtime_target(runtime_action),
         {:ok, next_state} <- apply_action(state, descriptor, runtime_action) do
      {:ok, State.sync_navigation_assigns(next_state)}
    end
  end

  @spec screen_id(t() | map()) :: atom() | String.t() | nil
  def screen_id(%{active: %{screen_id: screen_id}}), do: screen_id
  def screen_id(_other), do: nil

  @spec screen_title(t() | map()) :: String.t() | nil
  def screen_title(%{active: %{title: title}}), do: title
  def screen_title(_other), do: nil

  @spec assign_overlays(t() | map()) :: map()
  def assign_overlays(%{
        active: active,
        history: history,
        forward: forward,
        modals: modals,
        last_transition: last_transition,
        last_host_route: last_host_route
      }) do
    %{
      current_screen_id: active.screen_id,
      current_screen_title: active.title,
      navigation_action: last_transition && last_transition.action,
      navigation_params: normalize_map(active.params),
      navigation_history: Enum.map(history, &entry_summary/1),
      navigation_forward: Enum.map(forward, &entry_summary/1),
      navigation_modal_stack: Enum.map(modals, &modal_summary/1),
      current_modal: modals |> List.last() |> modal_summary(),
      navigation_host_route: last_host_route
    }
  end

  def assign_overlays(_other), do: %{}

  @spec strip_managed_assigns(map()) :: map()
  def strip_managed_assigns(assigns) when is_map(assigns) do
    Map.drop(assigns, @managed_assign_keys)
  end

  defp apply_action(%State{} = state, descriptor, runtime_action) do
    action = Map.get(descriptor, :action)

    case action do
      action when action in [:navigate_to, "navigate_to"] ->
        transition_to_screen(state, descriptor, runtime_action, :push_history)

      action when action in [:replace_with, "replace_with"] ->
        transition_to_screen(state, descriptor, runtime_action, :replace_current)

      action when action in [:go_back, "go_back"] ->
        move_history(state, descriptor, :back)

      action when action in [:go_forward, "go_forward"] ->
        move_history(state, descriptor, :forward)

      action when action in [:open_modal, "open_modal"] ->
        open_modal(state, descriptor)

      action when action in [:close_modal, "close_modal"] ->
        close_modal(state, descriptor)

      _other ->
        {:error,
         Error.unsupported_navigation_context(action, %{
           reason: :unsupported_navigation_action
         })}
    end
  end

  defp transition_to_screen(%State{} = state, descriptor, runtime_action, strategy) do
    with {:ok, resolution} <- resolve_screen(state, descriptor),
         {:ok, host_route} <- resolve_host_route(state, descriptor, resolution) do
      current = state.navigation.active
      active = entry_from_resolution(resolution, host_route)

      navigation =
        state.navigation
        |> put_active(active)
        |> put_last_transition(runtime_action, descriptor)
        |> put_last_host_route(host_route)
        |> reset_modal_stack()
        |> update_history(current, strategy)

      {:ok, apply_resolution(state, resolution, navigation)}
    end
  end

  defp move_history(%State{} = state, descriptor, direction) do
    navigation = state.navigation

    case direction do
      :back ->
        case back_target(navigation) do
          {:ok, target, history, forward} ->
            apply_history_transition(state, descriptor, target, history, [
              navigation.active | forward
            ])

          :empty ->
            {:error,
             Error.unsupported_navigation_context(descriptor.action, %{reason: :empty_history})}
        end

      :forward ->
        case forward_target(navigation) do
          {:ok, target, history, forward} ->
            apply_history_transition(
              state,
              descriptor,
              target,
              history ++ [navigation.active],
              forward
            )

          :empty ->
            {:error,
             Error.unsupported_navigation_context(descriptor.action, %{reason: :empty_history})}
        end
    end
  end

  defp apply_history_transition(state, descriptor, target, history, forward) do
    with {:ok, resolution} <- resolution_from_entry(target),
         {:ok, host_route} <- resolve_host_route(state, descriptor, resolution, target.host_route) do
      updated_navigation =
        state.navigation
        |> put_active(%{target | host_route: host_route})
        |> put_last_transition(%{family: :navigation, intent: descriptor.action}, descriptor)
        |> put_last_host_route(host_route)
        |> Map.put(:history, history)
        |> Map.put(:forward, forward)

      {:ok, apply_resolution(state, resolution, updated_navigation)}
    end
  end

  defp open_modal(%State{} = state, descriptor) do
    modal_id = Map.get(descriptor, :modal)

    if modal_id in [nil, ""] do
      {:error, Error.unsupported_navigation_context(descriptor.action, %{reason: :missing_modal})}
    else
      modal_entry = %{
        modal: modal_id,
        params: normalize_map(Map.get(descriptor, :params, %{})),
        metadata: normalize_map(Map.get(descriptor, :metadata, %{}))
      }

      navigation =
        state.navigation
        |> Map.update!(:modals, &(&1 ++ [modal_entry]))
        |> put_last_transition(%{family: :navigation, intent: descriptor.action}, descriptor)

      {:ok, %{state | navigation: navigation}}
    end
  end

  defp close_modal(%State{} = state, descriptor) do
    modal_id = Map.get(descriptor, :modal)

    case pop_modal(state.navigation.modals, modal_id) do
      {:ok, modals} ->
        navigation =
          state.navigation
          |> Map.put(:modals, modals)
          |> put_last_transition(%{family: :navigation, intent: descriptor.action}, descriptor)

        {:ok, %{state | navigation: navigation}}

      :error ->
        {:error,
         Error.unsupported_navigation_context(descriptor.action, %{
           reason: :missing_modal,
           modal: modal_id
         })}
    end
  end

  defp resolve_screen(%State{} = state, descriptor) do
    screen_id = Map.get(descriptor, :screen)

    with {:ok, candidate} <- resolve_candidate(state.navigation, screen_id, descriptor, state),
         {:ok, resolution} <- normalize_resolution(candidate, screen_id, descriptor) do
      {:ok, resolution}
    else
      {:error, reason} ->
        {:error,
         Error.unresolved_navigation_target(Map.get(descriptor, :action), screen_id, reason)}
    end
  end

  defp resolve_candidate(%{resolver: resolver} = navigation, screen_id, descriptor, state)
       when is_function(resolver, 2) do
    case resolver.(descriptor, state) do
      {:ok, candidate} -> {:ok, candidate}
      {:error, _reason} = error -> error
      nil -> lookup_registry(navigation.registry, screen_id)
      candidate -> {:ok, candidate}
    end
  end

  defp resolve_candidate(%{registry: registry}, screen_id, _descriptor, _state) do
    lookup_registry(registry, screen_id)
  end

  defp resolve_host_route(%State{} = state, descriptor, resolution, fallback \\ nil) do
    case state.navigation.host_route_resolver do
      resolver when is_function(resolver, 2) ->
        case resolver.(host_route_descriptor(descriptor, resolution), state) do
          {:ok, nil} ->
            {:ok, fallback}

          {:ok, route} when is_map(route) ->
            {:ok, Map.new(route)}

          nil ->
            {:ok, fallback}

          route when is_map(route) ->
            {:ok, Map.new(route)}

          {:error, reason} ->
            {:error,
             Error.unsupported_navigation_context(Map.get(descriptor, :action), %{
               reason: :invalid_host_route_resolution,
               details: inspect(reason)
             })}

          other ->
            {:error,
             Error.unsupported_navigation_context(Map.get(descriptor, :action), %{
               reason: :invalid_host_route_resolution,
               details: inspect(other)
             })}
        end

      _other ->
        {:ok, fallback}
    end
  end

  defp resolution_from_entry(
         %{mode: :native, screen_ref: screen_ref, screen_id: screen_id} = entry
       )
       when is_atom(screen_ref) do
    normalize_resolution(
      %{screen: screen_ref, screen_id: screen_id, title: entry.title},
      screen_id,
      %{
        params: entry.params,
        metadata: entry.metadata
      }
    )
  end

  defp resolution_from_entry(
         %{mode: :canonical, screen_ref: %Element{} = screen_ref, screen_id: screen_id} = entry
       ) do
    normalize_resolution(
      %{element: screen_ref, screen_id: screen_id, title: entry.title},
      screen_id,
      %{
        params: entry.params,
        metadata: entry.metadata
      }
    )
  end

  defp resolution_from_entry(entry) do
    {:error, {:invalid_navigation_entry, entry.screen_id}}
  end

  defp normalize_resolution(candidate, fallback_screen_id, descriptor)
       when is_atom(candidate) do
    if valid_screen_module?(candidate) do
      {:ok,
       %{
         mode: :native,
         screen: candidate,
         screen_ref: candidate,
         screen_id: fallback_screen_id || candidate.id(),
         title: candidate.title(),
         defaults: candidate.mount_defaults(),
         assigns: %{},
         params: normalize_map(Map.get(descriptor, :params, %{})),
         metadata: normalize_map(Map.get(descriptor, :metadata, %{}))
       }}
    else
      {:error, {:invalid_screen_module, candidate}}
    end
  end

  defp normalize_resolution(%Element{} = element, fallback_screen_id, descriptor) do
    {:ok,
     %{
       mode: :canonical,
       screen: CanonicalScreen,
       screen_ref: element,
       screen_id: fallback_screen_id || element.id || "canonical-screen",
       title: fallback_screen_title(element, fallback_screen_id),
       defaults: %{},
       assigns: %{iur: element},
       params: normalize_map(Map.get(descriptor, :params, %{})),
       metadata: normalize_map(Map.get(descriptor, :metadata, %{}))
     }}
  end

  defp normalize_resolution(candidate, fallback_screen_id, descriptor) when is_map(candidate) do
    assigns = normalize_map(Map.get(candidate, :assigns, %{}))

    screen_id =
      Map.get(candidate, :screen_id) || Map.get(candidate, "screen_id") || fallback_screen_id

    title = Map.get(candidate, :title) || Map.get(candidate, "title")
    metadata = normalize_map(Map.get(candidate, :metadata, %{}))
    params = normalize_map(Map.get(descriptor, :params, %{}))
    descriptor_metadata = normalize_map(Map.get(descriptor, :metadata, %{}))

    cond do
      valid_screen_module?(Map.get(candidate, :screen) || Map.get(candidate, "screen")) ->
        screen = Map.get(candidate, :screen) || Map.get(candidate, "screen")

        {:ok,
         %{
           mode: :native,
           screen: screen,
           screen_ref: screen,
           screen_id: screen_id || screen.id(),
           title: title || screen.title(),
           defaults: screen.mount_defaults(),
           assigns: assigns,
           params: params,
           metadata: Map.merge(metadata, descriptor_metadata)
         }}

      match?(%Element{}, Map.get(candidate, :element) || Map.get(candidate, "element")) ->
        element = Map.get(candidate, :element) || Map.get(candidate, "element")

        {:ok,
         %{
           mode: :canonical,
           screen: CanonicalScreen,
           screen_ref: element,
           screen_id: screen_id || element.id || "canonical-screen",
           title: title || fallback_screen_title(element, screen_id),
           defaults: %{},
           assigns: Map.put(assigns, :iur, element),
           params: params,
           metadata: Map.merge(metadata, descriptor_metadata)
         }}

      match?(%Element{}, Map.get(candidate, :iur) || Map.get(candidate, "iur")) ->
        element = Map.get(candidate, :iur) || Map.get(candidate, "iur")

        {:ok,
         %{
           mode: :canonical,
           screen: CanonicalScreen,
           screen_ref: element,
           screen_id: screen_id || element.id || "canonical-screen",
           title: title || fallback_screen_title(element, screen_id),
           defaults: %{},
           assigns: Map.put(assigns, :iur, element),
           params: params,
           metadata: Map.merge(metadata, descriptor_metadata)
         }}

      true ->
        {:error, {:unsupported_navigation_target, inspect(candidate)}}
    end
  end

  defp normalize_resolution(other, _fallback_screen_id, _descriptor) do
    {:error, {:unsupported_navigation_target, inspect(other)}}
  end

  defp apply_resolution(%State{} = state, resolution, navigation) do
    preserved_assigns =
      state.assigns
      |> strip_managed_assigns()
      |> Map.drop([:iur])

    next_assigns =
      resolution.defaults
      |> normalize_map()
      |> Map.merge(preserved_assigns)
      |> Map.merge(normalize_map(resolution.assigns))

    %{
      state
      | screen: resolution.screen,
        assigns: next_assigns,
        mode: resolution.mode,
        event_routes: resolution.screen.event_routes(),
        bridge_hooks:
          LiveUi.Runtime.BrowserBridge.normalize_hooks(resolution.screen.bridge_hooks()),
        navigation: navigation
    }
  end

  defp current_entry(screen, assigns, mode, opts) do
    screen_id =
      Keyword.get(opts, :screen_id) || current_screen_id(screen, assigns, mode)

    title =
      Keyword.get(opts, :title) || current_screen_title(screen, assigns, mode)

    %{
      screen_id: screen_id,
      title: title,
      mode: mode,
      screen_ref: current_screen_ref(screen, assigns, mode),
      params: normalize_map(Keyword.get(opts, :navigation_params, %{})),
      metadata: normalize_map(Keyword.get(opts, :navigation_metadata, %{})),
      host_route: nil
    }
  end

  defp current_screen_id(_screen, %{iur: %Element{id: id}}, :canonical) when not is_nil(id),
    do: id

  defp current_screen_id(screen, _assigns, _mode), do: screen.id()

  defp current_screen_title(_screen, %{iur: %Element{id: id}}, :canonical),
    do: fallback_screen_title(%Element{id: id}, id)

  defp current_screen_title(screen, _assigns, _mode), do: screen.title()

  defp current_screen_ref(_screen, %{iur: %Element{} = element}, :canonical), do: element
  defp current_screen_ref(screen, _assigns, _mode), do: screen

  defp back_target(%{history: []}), do: :empty

  defp back_target(%{history: history, forward: forward}) do
    {remainder, [target]} = Enum.split(history, -1)
    {:ok, target, remainder, forward}
  end

  defp forward_target(%{forward: []}), do: :empty

  defp forward_target(%{history: history, forward: [target | remainder]}) do
    {:ok, target, history, remainder}
  end

  defp put_active(navigation, active), do: %{navigation | active: active}

  defp put_last_transition(navigation, runtime_action, descriptor) do
    %{navigation | last_transition: transition_summary(runtime_action, descriptor)}
  end

  defp put_last_host_route(navigation, host_route),
    do: %{navigation | last_host_route: host_route}

  defp reset_modal_stack(navigation), do: %{navigation | modals: []}

  defp update_history(navigation, current, :push_history) do
    %{navigation | history: navigation.history ++ [current], forward: []}
  end

  defp update_history(navigation, _current, :replace_current) do
    %{navigation | forward: []}
  end

  defp entry_from_resolution(resolution, host_route) do
    %{
      screen_id: resolution.screen_id,
      title: resolution.title,
      mode: resolution.mode,
      screen_ref: resolution.screen_ref,
      params: resolution.params,
      metadata: resolution.metadata,
      host_route: host_route
    }
  end

  defp transition_summary(runtime_action, descriptor) do
    %{
      family: Map.get(runtime_action, :family, :navigation),
      intent: Map.get(runtime_action, :intent),
      action: Map.get(descriptor, :action),
      screen: Map.get(descriptor, :screen),
      modal: Map.get(descriptor, :modal),
      params: normalize_map(Map.get(descriptor, :params, %{})),
      metadata: normalize_map(Map.get(descriptor, :metadata, %{})),
      modal_stack: normalize_map(Map.get(descriptor, :modal_stack, %{}))
    }
  end

  defp host_route_descriptor(descriptor, resolution) do
    %{
      action: Map.get(descriptor, :action),
      screen: resolution.screen_id,
      modal: Map.get(descriptor, :modal),
      params: resolution.params,
      metadata: resolution.metadata,
      mode: resolution.mode
    }
  end

  defp navigation_descriptor(runtime_action) do
    case Interaction.navigation_descriptor(Map.get(runtime_action, :target, %{})) do
      nil ->
        {:error,
         Error.unsupported_navigation_context(Map.get(runtime_action, :intent), %{
           reason: :missing_navigation_descriptor
         })}

      descriptor ->
        {:ok, normalize_map(descriptor)}
    end
  end

  defp validate_runtime_target(runtime_action) do
    target = normalize_map(Map.get(runtime_action, :target, %{}))
    navigation = normalize_map(raw_navigation_descriptor(target) || %{})

    leaked_keys = forbidden_navigation_keys(navigation)

    if leaked_keys == [] do
      :ok
    else
      {:error, Error.host_route_navigation_syntax(leaked_keys)}
    end
  end

  defp raw_navigation_descriptor(target) when is_map(target) do
    Map.get(target, :navigation) || Map.get(target, "navigation")
  end

  defp raw_navigation_descriptor(_other), do: nil

  defp forbidden_navigation_keys(navigation) do
    modal_stack =
      navigation
      |> Map.get(:modal_stack, Map.get(navigation, "modal_stack", %{}))
      |> normalize_map()

    (Map.keys(navigation) ++ Map.keys(modal_stack))
    |> Enum.filter(&forbidden_navigation_key?/1)
    |> Enum.uniq()
  end

  defp lookup_registry(registry, screen_id) when is_map(registry) do
    case Enum.find(registry, fn {key, _value} -> key_matches?(key, screen_id) end) do
      nil -> {:error, :unknown_screen}
      {_key, value} -> {:ok, value}
    end
  end

  defp key_matches?(key, value), do: key == value or to_string(key) == to_string(value)

  defp valid_screen_module?(screen) when is_atom(screen) do
    Code.ensure_loaded?(screen) and function_exported?(screen, :id, 0) and
      function_exported?(screen, :title, 0) and function_exported?(screen, :mount_defaults, 0) and
      function_exported?(screen, :render, 1) and function_exported?(screen, :event_routes, 0) and
      function_exported?(screen, :bridge_hooks, 0) and
      function_exported?(screen, :handle_event, 3)
  end

  defp valid_screen_module?(_screen), do: false

  defp fallback_screen_title(%Element{id: id}, fallback_screen_id) do
    (id || fallback_screen_id || "Canonical Screen")
    |> to_string()
    |> String.replace("_", " ")
    |> String.replace("-", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp pop_modal([], _modal_id), do: :error

  defp pop_modal(modals, nil), do: {:ok, Enum.drop(modals, -1)}

  defp pop_modal(modals, modal_id) do
    if Enum.any?(modals, &(Map.get(&1, :modal) == modal_id)) do
      {:ok, remove_last_modal(modals, modal_id)}
    else
      :error
    end
  end

  defp remove_last_modal(modals, modal_id) do
    {reversed_kept, dropped?} =
      modals
      |> Enum.reverse()
      |> Enum.reduce({[], false}, fn modal, {acc, dropped?} ->
        if not dropped? and Map.get(modal, :modal) == modal_id do
          {acc, true}
        else
          {[modal | acc], dropped?}
        end
      end)

    if dropped?, do: reversed_kept, else: modals
  end

  defp entry_summary(nil), do: nil

  defp entry_summary(entry) do
    %{
      screen_id: entry.screen_id,
      title: entry.title,
      mode: entry.mode,
      params: normalize_map(entry.params)
    }
  end

  defp modal_summary(nil), do: nil

  defp modal_summary(modal) do
    %{
      modal: Map.get(modal, :modal),
      params: normalize_map(Map.get(modal, :params, %{})),
      metadata: normalize_map(Map.get(modal, :metadata, %{}))
    }
  end

  defp forbidden_navigation_key?(key) when is_atom(key),
    do: key in BoundaryTransport.forbidden_navigation_keys()

  defp forbidden_navigation_key?(key) when is_binary(key) do
    key in Enum.map(BoundaryTransport.forbidden_navigation_keys(), &Atom.to_string/1)
  end

  defp forbidden_navigation_key?(_key), do: false

  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(list) when is_list(list), do: Enum.into(list, %{})
  defp normalize_map(_other), do: %{}
end
