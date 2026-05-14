defmodule ElmUi.ServerRuntime.Navigation do
  @moduledoc """
  Authoritative screen-transition resolver for the Phoenix side of `elm_ui`.
  """

  alias UnifiedIUR.{Element, Interaction}
  alias UnifiedIUR.Interactions.Transport, as: BoundaryTransport
  alias ElmUi.ServerRuntime.{Error, State}

  @type screen_ref :: map() | Element.t()
  @type resolver :: (map(), State.t() -> {:ok, term()} | {:error, term()} | term())
  @type host_route_resolver :: (map(), State.t() ->
                                  map() | nil | {:ok, map() | nil} | {:error, term()})

  @type entry :: %{
          screen_id: String.t() | atom(),
          title: String.t(),
          source_kind: :native | :canonical,
          boundary_mode: State.boundary_mode(),
          screen_ref: screen_ref(),
          params: map(),
          metadata: map(),
          host_route: map() | nil
        }

  @type t :: %{
          registry: map(),
          resolver: resolver() | nil,
          host_route_resolver: host_route_resolver() | nil,
          active: entry(),
          history: [entry()],
          forward: [entry()],
          modals: [map()],
          last_transition: map() | nil,
          last_host_route: map() | nil
        }

  @spec initialize(:native | :canonical, map(), Element.t() | nil, keyword()) :: t()
  def initialize(source_kind, screen, canonical_element, opts) when is_map(screen) do
    active = current_entry(source_kind, screen, canonical_element, opts)

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
  def apply_transition(%State{} = state, translation) when is_map(translation) do
    with {:ok, descriptor} <- navigation_descriptor(translation),
         :ok <- validate_runtime_target(translation),
         {:ok, next_state} <- apply_action(state, descriptor, translation) do
      {:ok, next_state}
    end
  end

  @spec summary(t() | map()) :: map()
  def summary(%{
        active: active,
        history: history,
        forward: forward,
        modals: modals,
        last_transition: last_transition,
        last_host_route: last_host_route
      }) do
    %{
      current_screen_id: active.screen_id,
      current_title: active.title,
      params: normalize_map(active.params),
      history: Enum.map(history, &entry_summary/1),
      forward: Enum.map(forward, &entry_summary/1),
      modals: Enum.map(modals, &modal_summary/1),
      current_modal: modals |> List.last() |> modal_summary(),
      last_transition: last_transition,
      host_route: last_host_route
    }
  end

  def summary(_other), do: %{}

  @spec authoritative_screen_payload(State.t()) :: map()
  def authoritative_screen_payload(%State{} = state) do
    %{
      screen_id: state.screen_id,
      title: state.title,
      source_kind: state.source_kind,
      boundary_mode: state.boundary_mode,
      tree:
        ElmUi.ServerRuntime.RenderModel.build(
          state.rendered_tree,
          theme: Map.get(state.metadata, :theme, :default)
        ),
      metadata: Map.put(state.metadata, :navigation, summary(state.navigation))
    }
  end

  defp apply_action(%State{} = state, descriptor, translation) do
    action = Map.get(descriptor, :action)

    case action do
      action when action in [:navigate_to, "navigate_to"] ->
        transition_to_screen(state, descriptor, translation, :push_history)

      action when action in [:replace_with, "replace_with"] ->
        transition_to_screen(state, descriptor, translation, :replace_current)

      action when action in [:go_back, "go_back"] ->
        move_history(state, descriptor, translation, :back)

      action when action in [:go_forward, "go_forward"] ->
        move_history(state, descriptor, translation, :forward)

      action when action in [:open_modal, "open_modal"] ->
        open_modal(state, descriptor, translation)

      action when action in [:close_modal, "close_modal"] ->
        close_modal(state, descriptor, translation)

      _other ->
        {:error,
         Error.new(:unsupported_navigation_context, "Unsupported navigation transition action", %{
           action: action
         })}
    end
  end

  defp transition_to_screen(%State{} = state, descriptor, translation, strategy) do
    with {:ok, resolution} <- resolve_screen(state, descriptor),
         {:ok, host_route} <- resolve_host_route(state, descriptor, resolution) do
      current = state.navigation.active

      navigation =
        state.navigation
        |> Map.put(:active, entry_from_resolution(resolution, host_route))
        |> Map.put(:last_transition, transition_summary(translation, descriptor))
        |> Map.put(:last_host_route, host_route)
        |> Map.put(:modals, [])
        |> update_history(current, strategy)

      state =
        state
        |> apply_resolution(resolution, navigation)
        |> maybe_record_route_state_diagnostic(translation, resolution, host_route)

      {:ok, state}
    end
  end

  defp move_history(%State{} = state, descriptor, translation, direction) do
    navigation = state.navigation

    case direction do
      :back ->
        case back_target(navigation) do
          {:ok, target, history, forward} ->
            apply_history_transition(
              state,
              descriptor,
              translation,
              target,
              history,
              [navigation.active | forward]
            )

          :empty ->
            {:error,
             Error.new(
               :unsupported_navigation_context,
               "Cannot go back without navigation history",
               %{
                 action: descriptor.action
               }
             )}
        end

      :forward ->
        case forward_target(navigation) do
          {:ok, target, history, forward} ->
            apply_history_transition(
              state,
              descriptor,
              translation,
              target,
              history ++ [navigation.active],
              forward
            )

          :empty ->
            {:error,
             Error.new(
               :unsupported_navigation_context,
               "Cannot go forward without forward navigation state",
               %{action: descriptor.action}
             )}
        end
    end
  end

  defp apply_history_transition(state, descriptor, translation, target, history, forward) do
    with {:ok, resolution} <- resolution_from_entry(target),
         {:ok, host_route} <- resolve_host_route(state, descriptor, resolution, target.host_route) do
      navigation =
        state.navigation
        |> Map.put(:active, %{target | host_route: host_route})
        |> Map.put(:history, history)
        |> Map.put(:forward, forward)
        |> Map.put(:last_transition, transition_summary(translation, descriptor))
        |> Map.put(:last_host_route, host_route)

      state =
        state
        |> apply_resolution(resolution, navigation)
        |> maybe_record_route_state_diagnostic(translation, resolution, host_route)

      {:ok, state}
    end
  end

  defp open_modal(%State{} = state, descriptor, translation) do
    modal_id = Map.get(descriptor, :modal)

    if modal_id in [nil, ""] do
      {:error,
       Error.new(:unsupported_navigation_context, "open_modal requires a modal identifier", %{
         action: descriptor.action
       })}
    else
      modal_entry = %{
        modal: modal_id,
        params: normalize_map(Map.get(descriptor, :params, %{})),
        metadata: normalize_map(Map.get(descriptor, :metadata, %{}))
      }

      {:ok,
       %{
         state
         | navigation: %{
             state.navigation
             | modals: state.navigation.modals ++ [modal_entry],
               last_transition: transition_summary(translation, descriptor)
           }
       }}
    end
  end

  defp close_modal(%State{} = state, descriptor, translation) do
    case pop_modal(state.navigation.modals, Map.get(descriptor, :modal)) do
      {:ok, modals} ->
        {:ok,
         %{
           state
           | navigation: %{
               state.navigation
               | modals: modals,
                 last_transition: transition_summary(translation, descriptor)
             }
         }}

      :error ->
        {:error,
         Error.new(:unsupported_navigation_context, "Requested modal is not open", %{
           action: descriptor.action,
           modal: Map.get(descriptor, :modal)
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
         Error.new(
           :unresolved_navigation_target,
           "Unable to resolve symbolic navigation target",
           %{
             action: Map.get(descriptor, :action),
             screen_id: screen_id,
             reason: inspect(reason)
           }
         )}
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
             Error.new(
               :unsupported_navigation_context,
               "Host-route integration returned an invalid result",
               %{reason: inspect(reason)}
             )}

          other ->
            {:error,
             Error.new(
               :unsupported_navigation_context,
               "Host-route integration returned an invalid result",
               %{reason: inspect(other)}
             )}
        end

      _other ->
        {:ok, fallback}
    end
  end

  defp normalize_resolution(%Element{} = element, fallback_screen_id, descriptor) do
    with {:ok, root} <- ElmUi.Renderer.render(element) do
      {:ok,
       %{
         source_kind: :canonical,
         boundary_mode: :canonical_boundary,
         screen_id: fallback_screen_id || element.id || "canonical-screen",
         title: fallback_screen_title(element, fallback_screen_id),
         rendered_tree: root,
         canonical_element: element,
         metadata: normalize_map(Map.get(descriptor, :metadata, %{})),
         params: normalize_map(Map.get(descriptor, :params, %{})),
         screen_ref: element
       }}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  defp normalize_resolution(candidate, fallback_screen_id, descriptor) when is_map(candidate) do
    metadata =
      candidate
      |> Map.get(:metadata, %{})
      |> normalize_map()
      |> Map.merge(normalize_map(Map.get(descriptor, :metadata, %{})))

    params = normalize_map(Map.get(descriptor, :params, %{}))

    cond do
      valid_native_screen?(candidate) ->
        {:ok,
         %{
           source_kind: :native,
           boundary_mode: :native_local,
           screen_id: Map.get(candidate, :id) || fallback_screen_id,
           title: Map.get(candidate, :title, "Screen"),
           rendered_tree: Map.get(candidate, :root),
           canonical_element: nil,
           metadata: metadata,
           params: params,
           screen_ref: candidate
         }}

      match?(%Element{}, Map.get(candidate, :element) || Map.get(candidate, "element")) ->
        normalize_resolution(
          Map.get(candidate, :element) || Map.get(candidate, "element"),
          Map.get(candidate, :screen_id) || fallback_screen_id,
          %{
            params: params,
            metadata: metadata |> Map.merge(normalize_map(Map.get(candidate, :metadata, %{})))
          }
        )

      match?(%Element{}, Map.get(candidate, :iur) || Map.get(candidate, "iur")) ->
        normalize_resolution(
          Map.get(candidate, :iur) || Map.get(candidate, "iur"),
          Map.get(candidate, :screen_id) || fallback_screen_id,
          %{
            params: params,
            metadata: metadata |> Map.merge(normalize_map(Map.get(candidate, :metadata, %{})))
          }
        )

      valid_native_screen?(Map.get(candidate, :screen) || Map.get(candidate, "screen")) ->
        screen = Map.get(candidate, :screen) || Map.get(candidate, "screen")

        normalize_resolution(
          screen,
          Map.get(candidate, :screen_id) || fallback_screen_id,
          %{
            params: params,
            metadata: metadata |> Map.merge(normalize_map(Map.get(candidate, :metadata, %{})))
          }
        )

      true ->
        {:error, {:unsupported_navigation_target, inspect(candidate)}}
    end
  end

  defp normalize_resolution(other, _fallback_screen_id, _descriptor) do
    {:error, {:unsupported_navigation_target, inspect(other)}}
  end

  defp resolution_from_entry(%{source_kind: :canonical, screen_ref: %Element{} = element} = entry) do
    normalize_resolution(element, entry.screen_id, %{
      params: entry.params,
      metadata: entry.metadata
    })
  end

  defp resolution_from_entry(%{source_kind: :native, screen_ref: screen} = entry)
       when is_map(screen) do
    normalize_resolution(screen, entry.screen_id, %{
      params: entry.params,
      metadata: entry.metadata
    })
  end

  defp resolution_from_entry(entry) do
    {:error, {:invalid_navigation_entry, entry.screen_id}}
  end

  defp apply_resolution(%State{} = state, resolution, navigation) do
    metadata =
      state.metadata
      |> normalize_map()
      |> Map.drop([:navigation])
      |> Map.merge(normalize_map(resolution.metadata))

    %{
      state
      | source_kind: resolution.source_kind,
        title: resolution.title,
        screen_id: resolution.screen_id,
        rendered_tree: resolution.rendered_tree,
        canonical_element: resolution.canonical_element,
        boundary_mode: resolution.boundary_mode,
        navigation: navigation,
        metadata: metadata
    }
  end

  defp current_entry(source_kind, screen, canonical_element, _opts) do
    %{
      screen_id: Map.get(screen, :id),
      title: Map.get(screen, :title, "Screen"),
      source_kind: source_kind,
      boundary_mode: if(source_kind == :canonical, do: :canonical_boundary, else: :native_local),
      screen_ref: if(source_kind == :canonical, do: canonical_element, else: screen),
      params: %{},
      metadata: normalize_map(Map.get(screen, :metadata, %{})),
      host_route: nil
    }
  end

  defp maybe_record_route_state_diagnostic(%State{} = state, translation, resolution, host_route) do
    case route_state_diagnostic(translation, resolution, host_route) do
      nil -> state
      diagnostic -> State.record_diagnostic(state, diagnostic)
    end
  end

  defp route_state_diagnostic(translation, resolution, host_route) do
    metadata =
      translation
      |> Map.get(:metadata, %{})
      |> normalize_map()

    route_state =
      metadata
      |> Map.get(:route_state, Map.get(metadata, "route_state", %{}))
      |> normalize_map()

    reported_screen =
      Map.get(route_state, :screen_id) || Map.get(route_state, "screen_id") ||
        Map.get(route_state, :screen) || Map.get(route_state, "screen")

    reported_path = Map.get(route_state, :path) || Map.get(route_state, "path")
    expected_path = host_route && (Map.get(host_route, :path) || Map.get(host_route, "path"))

    cond do
      route_state == %{} ->
        nil

      not is_nil(reported_screen) and
          to_string(reported_screen) != to_string(resolution.screen_id) ->
        %{
          level: :warning,
          reason: :frontend_route_state_divergence,
          reported_screen: reported_screen,
          authoritative_screen: resolution.screen_id
        }

      not is_nil(reported_path) and not is_nil(expected_path) and reported_path != expected_path ->
        %{
          level: :warning,
          reason: :frontend_route_state_divergence,
          reported_path: reported_path,
          authoritative_path: expected_path
        }

      true ->
        nil
    end
  end

  defp back_target(%{history: []}), do: :empty

  defp back_target(%{history: history, forward: forward}) do
    {remainder, [target]} = Enum.split(history, -1)
    {:ok, target, remainder, forward}
  end

  defp forward_target(%{forward: []}), do: :empty

  defp forward_target(%{history: history, forward: [target | remainder]}) do
    {:ok, target, history, remainder}
  end

  defp update_history(navigation, current, :push_history) do
    %{navigation | history: navigation.history ++ [current], forward: []}
  end

  defp update_history(navigation, _current, :replace_current) do
    %{navigation | forward: []}
  end

  defp navigation_descriptor(translation) do
    case Interaction.navigation_descriptor(Map.get(translation, :target, %{})) do
      nil ->
        {:error,
         Error.new(
           :unsupported_navigation_context,
           "Navigation transitions require a canonical target descriptor",
           %{
             intent: Map.get(translation, :intent)
           }
         )}

      descriptor ->
        {:ok, normalize_map(descriptor)}
    end
  end

  defp validate_runtime_target(translation) do
    target = normalize_map(Map.get(translation, :target, %{}))
    navigation = normalize_map(raw_navigation_descriptor(target) || %{})

    leaked_keys = forbidden_navigation_keys(navigation)

    if leaked_keys == [] do
      :ok
    else
      {:error,
       Error.new(
         :host_route_syntax,
         "Canonical navigation targets must not contain host-router syntax",
         %{
           keys: leaked_keys
         }
       )}
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

  defp resolve_candidate(%{registry: registry}, screen_id) do
    case Enum.find(registry, fn {key, _value} -> key_matches?(key, screen_id) end) do
      nil -> {:error, :unknown_screen}
      {_key, value} -> {:ok, value}
    end
  end

  defp lookup_registry(registry, screen_id) when is_map(registry),
    do: resolve_candidate(%{registry: registry}, screen_id)

  defp key_matches?(key, value), do: key == value or to_string(key) == to_string(value)

  defp valid_native_screen?(%{id: _id, title: _title, root: %ElmUi.Widget{}}), do: true
  defp valid_native_screen?(_other), do: false

  defp entry_from_resolution(resolution, host_route) do
    %{
      screen_id: resolution.screen_id,
      title: resolution.title,
      source_kind: resolution.source_kind,
      boundary_mode: resolution.boundary_mode,
      screen_ref: resolution.screen_ref,
      params: resolution.params,
      metadata: resolution.metadata,
      host_route: host_route
    }
  end

  defp transition_summary(translation, descriptor) do
    %{
      family: Map.get(translation, :family, :navigation),
      intent: Map.get(translation, :intent),
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
      source_kind: resolution.source_kind
    }
  end

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

  defp entry_summary(entry) do
    %{
      screen_id: entry.screen_id,
      title: entry.title,
      source_kind: entry.source_kind,
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
