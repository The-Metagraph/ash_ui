defmodule UnifiedUi.Dsl.Verifiers.ValidateThemesAndSignals do
  @moduledoc false

  use Spark.Dsl.Verifier

  alias Spark.Dsl.Verifier
  alias UnifiedIUR.Token
  alias UnifiedUi.{Binding, Signal, Style, Theme}
  alias UnifiedUi.Dsl.Node

  @renderer_local_keys [
    :phx_click,
    :phx_change,
    :phx_submit,
    :hook,
    :channel,
    :topic,
    :event,
    :event_name,
    :transport,
    :callback,
    :on_click,
    :on_change,
    :elm_msg,
    :dom_event,
    "phx_click",
    "phx_change",
    "phx_submit",
    "hook",
    "channel",
    "topic",
    "event",
    "event_name",
    "transport",
    "callback",
    "on_click",
    "on_change",
    "elm_msg",
    "dom_event"
  ]

  @renderer_local_sources [:phoenix, :live_view, :elm, :dom, :js, :sdl]
  @allowed_state_keys MapSet.new(Style.component_states())

  @spec verify(map()) :: :ok | {:error, Spark.Error.DslError.t()}
  def verify(dsl) do
    module = Verifier.get_persisted(dsl, :module)
    themes = Enum.filter(Verifier.get_entities(dsl, [:themes]), &match?(%Theme{}, &1))

    bindings =
      dsl
      |> Verifier.get_entities([:signals])
      |> Enum.filter(&match?(%Binding{}, &1))
      |> Enum.map(&Binding.new/1)

    interactions =
      dsl
      |> Verifier.get_entities([:signals])
      |> Enum.filter(&match?(%Signal{}, &1))
      |> Enum.map(&Signal.new/1)

    composition_nodes =
      dsl
      |> Verifier.get_entities([:composition])
      |> Enum.filter(&match?(%Node{}, &1))
      |> flatten_nodes()

    context = build_context(themes, bindings, interactions)

    with :ok <- validate_default_theme(module, dsl, context),
         :ok <- validate_themes(module, context),
         :ok <- validate_node_styles(module, composition_nodes, context),
         :ok <- validate_bindings(module, bindings, context),
         :ok <- validate_interactions(module, interactions, context),
         :ok <- validate_node_signal_refs(module, composition_nodes, context) do
      :ok
    end
  end

  defp build_context(themes, bindings, interactions) do
    %{
      theme_ids: MapSet.new(Enum.map(themes, & &1.id)),
      binding_ids: MapSet.new(Enum.map(bindings, & &1.id)),
      interaction_ids: MapSet.new(Enum.map(interactions, & &1.id)),
      palette_ids:
        themes
        |> Enum.flat_map(&Theme.palette_colors/1)
        |> Enum.map(& &1.id)
        |> MapSet.new(),
      token_ids:
        themes
        |> Enum.flat_map(&Theme.tokens/1)
        |> Enum.map(& &1.id)
        |> MapSet.new(),
      role_ids:
        themes
        |> Enum.flat_map(&Theme.semantic_roles/1)
        |> Enum.map(& &1.id)
        |> MapSet.new(),
      theme_component_style_ids:
        themes
        |> Enum.flat_map(&Theme.component_styles/1)
        |> Enum.map(& &1.id)
        |> MapSet.new(),
      theme_by_id: Map.new(themes, &{&1.id, &1})
    }
  end

  defp validate_default_theme(module, dsl, %{theme_ids: theme_ids}) do
    case Verifier.get_option(dsl, [:themes], :default_theme, nil) do
      nil ->
        :ok

      default_theme ->
        if MapSet.member?(theme_ids, default_theme) do
          :ok
        else
          dsl_error(
            module,
            [:themes],
            "themes.default_theme must reference a declared theme id, got #{inspect(default_theme)}"
          )
        end
    end
  end

  defp validate_themes(module, context) do
    context.theme_by_id
    |> Map.values()
    |> Enum.reduce_while(:ok, fn theme, :ok ->
      theme_ctx = theme_context(theme, context)

      case validate_theme(module, theme, theme_ctx) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp validate_theme(module, %Theme{} = theme, context) do
    cond do
      theme.extends == theme.id ->
        dsl_error(module, [:themes, :theme, theme.id], "theme may not extend itself")

      not is_nil(theme.extends) and not MapSet.member?(context.theme_ids, theme.extends) ->
        dsl_error(
          module,
          [:themes, :theme, theme.id],
          "theme.extends must reference another declared theme id, got #{inspect(theme.extends)}"
        )

      not is_nil(theme.extends) and theme.inherit? == false ->
        dsl_error(
          module,
          [:themes, :theme, theme.id],
          "theme.extends may only be used when theme.inherit? is true"
        )

      Theme.palette_colors(theme) == [] and Theme.tokens(theme) == [] and
          Theme.component_styles(theme) == [] ->
        dsl_error(
          module,
          [:themes, :theme, theme.id],
          "theme must declare palette colors, tokens, or component styles so authored theming is not empty"
        )

      true ->
        with :ok <- validate_semantic_roles(module, theme, context),
             :ok <- validate_tokens(module, theme, context),
             :ok <- validate_component_styles(module, theme, context) do
          :ok
        end
    end
  end

  defp validate_semantic_roles(module, theme, context) do
    Theme.semantic_roles(theme)
    |> Enum.reduce_while(:ok, fn role, :ok ->
      case validate_color_reference(
             role.value,
             context,
             module,
             [:themes, :theme, theme.id, :semantic_role, role.id]
           ) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp validate_tokens(module, theme, context) do
    Theme.tokens(theme)
    |> Enum.reduce_while(:ok, fn token, :ok ->
      case token.value do
        %Style{} = style ->
          case validate_style(
                 style,
                 context,
                 module,
                 [:themes, :theme, theme.id, :token, token.id]
               ) do
            :ok -> {:cont, :ok}
            error -> {:halt, error}
          end

        _other ->
          {:cont, :ok}
      end
    end)
  end

  defp validate_component_styles(module, theme, context) do
    Theme.component_styles(theme)
    |> Enum.reduce_while(:ok, fn component_style, :ok ->
      with :ok <-
             validate_token_refs(
               component_style.token_refs,
               context,
               module,
               [:themes, :theme, theme.id, :component_style, component_style.id]
             ),
           :ok <-
             validate_style(
               component_style.style,
               context,
               module,
               [:themes, :theme, theme.id, :component_style, component_style.id]
             ) do
        {:cont, :ok}
      else
        error -> {:halt, error}
      end
    end)
  end

  defp validate_node_styles(module, nodes, context) do
    Enum.reduce_while(nodes, :ok, fn node, :ok ->
      with :ok <- validate_node_theme_ref(module, node, context),
           :ok <- validate_style_refs(module, node, context),
           :ok <- validate_style(node.style, context, module, [:composition, node.kind, node.id]) do
        {:cont, :ok}
      else
        error -> {:halt, error}
      end
    end)
  end

  defp validate_node_theme_ref(_module, %Node{theme_ref: nil}, _context), do: :ok

  defp validate_node_theme_ref(module, %Node{} = node, %{theme_ids: theme_ids}) do
    if MapSet.member?(theme_ids, node.theme_ref) do
      :ok
    else
      dsl_error(
        module,
        [:composition, node.kind, node.id],
        "#{node.kind} :#{node.id} theme_ref must reference a declared theme id, got #{inspect(node.theme_ref)}"
      )
    end
  end

  defp validate_style_refs(_module, %Node{style_refs: []}, _context), do: :ok

  defp validate_style_refs(module, %Node{} = node, %{theme_component_style_ids: ids}) do
    case Enum.find(node.style_refs, &(not MapSet.member?(ids, &1))) do
      nil ->
        :ok

      missing ->
        dsl_error(
          module,
          [:composition, node.kind, node.id],
          "#{node.kind} :#{node.id} style_refs must reference declared component styles, got #{inspect(missing)}"
        )
    end
  end

  defp validate_style(nil, _context, _module, _path), do: :ok

  defp validate_style(style, context, module, path) do
    style = Style.new(style)

    with :ok <- validate_token_refs(style.token_refs, context, module, path ++ [:style]),
         :ok <-
           validate_color_reference(
             style.foreground,
             context,
             module,
             path ++ [:style, :foreground]
           ),
         :ok <-
           validate_color_reference(
             style.background,
             context,
             module,
             path ++ [:style, :background]
           ),
         :ok <-
           validate_color_reference(
             style.border_color,
             context,
             module,
             path ++ [:style, :border_color]
           ),
         :ok <-
           validate_numeric_group(
             style.spacing,
             [:padding, :padding_x, :padding_y, :margin, :margin_x, :margin_y, :gap],
             module,
             path ++ [:style, :spacing]
           ),
         :ok <-
           validate_numeric_group(
             style.sizing,
             [:width, :height, :min_width, :min_height, :max_width, :max_height],
             module,
             path ++ [:style, :sizing]
           ),
         :ok <-
           validate_numeric_group(
             style.border,
             [:width, :radius],
             module,
             path ++ [:style, :border]
           ),
         :ok <- validate_opacity(style.visibility, module, path ++ [:style, :visibility]),
         :ok <- validate_state_variants(style.state_variants, context, module, path) do
      :ok
    end
  end

  defp validate_state_variants(state_variants, context, module, path) do
    Enum.reduce_while(state_variants, :ok, fn {state_key, variant}, :ok ->
      cond do
        not MapSet.member?(@allowed_state_keys, state_key) ->
          {:halt,
           dsl_error(
             module,
             path ++ [:style, :state_variants],
             "state variant #{inspect(state_key)} is not supported; expected one of #{inspect(MapSet.to_list(@allowed_state_keys))}"
           )}

        true ->
          case validate_style(
                 variant,
                 context,
                 module,
                 path ++ [:style, :state_variants, state_key]
               ) do
            :ok -> {:cont, :ok}
            error -> {:halt, error}
          end
      end
    end)
  end

  defp validate_numeric_group(values, _keys, _module, _path) when values in [%{}, nil], do: :ok

  defp validate_numeric_group(values, keys, module, path) do
    case Enum.find(keys, fn key ->
           value = Map.get(values, key)
           is_integer(value) and value < 0
         end) do
      nil ->
        :ok

      key ->
        dsl_error(module, path, "#{inspect(key)} must be zero or positive")
    end
  end

  defp validate_opacity(values, _module, _path) when values in [%{}, nil], do: :ok

  defp validate_opacity(values, module, path) do
    case Map.get(values, :opacity, Map.get(values, "opacity")) do
      nil ->
        :ok

      opacity when is_number(opacity) and opacity >= 0 and opacity <= 1 ->
        :ok

      opacity ->
        dsl_error(
          module,
          path,
          "visibility.opacity must be between 0.0 and 1.0, got #{inspect(opacity)}"
        )
    end
  end

  defp validate_color_reference(nil, _context, _module, _path), do: :ok

  defp validate_color_reference(value, context, module, path) do
    cond do
      Style.role_reference?(value) ->
        role_id = Map.get(value, :id, Map.get(value, "id"))

        if MapSet.member?(context.role_ids, role_id) do
          :ok
        else
          dsl_error(
            module,
            path,
            "role reference #{inspect(role_id)} must reference a declared semantic role"
          )
        end

      token_reference?(value) ->
        validate_single_token_ref(value, context, module, path)

      true ->
        :ok
    end
  end

  defp validate_token_refs([], _context, _module, _path), do: :ok

  defp validate_token_refs(token_refs, context, module, path) do
    Enum.reduce_while(token_refs, :ok, fn token_ref, :ok ->
      case validate_single_token_ref(token_ref, context, module, path) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp validate_single_token_ref(token_ref, context, module, path) do
    token_id = token_ref |> Token.new() |> then(&List.last(&1.path))

    if MapSet.member?(context.token_ids, token_id) or
         MapSet.member?(context.palette_ids, token_id) do
      :ok
    else
      dsl_error(
        module,
        path,
        "token reference #{inspect(token_id)} must reference a declared theme token or palette color"
      )
    end
  end

  defp validate_bindings(module, bindings, context) do
    Enum.reduce_while(bindings, :ok, fn binding, :ok ->
      with :ok <- validate_binding_path(module, binding),
           :ok <- validate_binding_source(module, binding),
           :ok <- validate_binding_dependencies(module, binding, context) do
        {:cont, :ok}
      else
        error -> {:halt, error}
      end
    end)
  end

  defp validate_binding_path(module, %Binding{id: id, path: []}) do
    dsl_error(module, [:signals, :data_binding, id], "binding path must not be empty")
  end

  defp validate_binding_path(_module, _binding), do: :ok

  defp validate_binding_source(_module, %Binding{source: nil}), do: :ok

  defp validate_binding_source(module, %Binding{id: id, source: source})
       when source in @renderer_local_sources do
    dsl_error(
      module,
      [:signals, :data_binding, id],
      "binding source #{inspect(source)} is renderer-local and not allowed in canonical UnifiedUi authoring"
    )
  end

  defp validate_binding_source(_module, _binding), do: :ok

  defp validate_binding_dependencies(module, %Binding{id: id, depends_on: refs}, %{
         binding_ids: binding_ids
       }) do
    case Enum.find(refs, fn %{id: ref_id} -> not MapSet.member?(binding_ids, ref_id) end) do
      nil ->
        :ok

      %{id: ref_id} ->
        dsl_error(
          module,
          [:signals, :data_binding, id],
          "binding depends_on references unknown binding #{inspect(ref_id)}"
        )
    end
  end

  defp validate_interactions(module, interactions, context) do
    Enum.reduce_while(interactions, :ok, fn interaction, :ok ->
      with :ok <- validate_interaction_target(module, interaction),
           :ok <-
             validate_runtime_local_keys(module, interaction.source_context, [
               :signals,
               :interaction,
               interaction.id,
               :source_context
             ]),
           :ok <-
             validate_runtime_local_keys(module, interaction.target_intent, [
               :signals,
               :interaction,
               interaction.id,
               :target_intent
             ]),
           :ok <-
             validate_runtime_local_keys(module, interaction.payload_mapping, [
               :signals,
               :interaction,
               interaction.id,
               :payload_mapping
             ]),
           :ok <-
             validate_binding_refs(module, interaction.id, interaction.binding_refs, context, [
               :signals,
               :interaction,
               interaction.id
             ]),
           :ok <-
             validate_payload_binding_refs(
               module,
               interaction.id,
               interaction.payload_mapping,
               context
             ) do
        {:cont, :ok}
      else
        error -> {:halt, error}
      end
    end)
  end

  defp validate_interaction_target(module, %Signal{
         id: id,
         intent: nil,
         target_intent: target_intent
       })
       when target_intent == %{} do
    dsl_error(
      module,
      [:signals, :interaction, id],
      "interaction must declare an intent or a target_intent so canonical event meaning is explicit"
    )
  end

  defp validate_interaction_target(_module, _interaction), do: :ok

  defp validate_runtime_local_keys(_module, values, _path) when values in [%{}, nil], do: :ok

  defp validate_runtime_local_keys(module, values, path) do
    case find_renderer_local_key(values) do
      nil ->
        :ok

      bad_key ->
        dsl_error(
          module,
          path,
          "renderer-local key #{inspect(bad_key)} is not allowed in canonical UnifiedUi signals"
        )
    end
  end

  defp validate_binding_refs(_module, _id, [], _context, _path), do: :ok

  defp validate_binding_refs(module, id, refs, %{binding_ids: binding_ids}, path) do
    case Enum.find(refs, fn %{id: ref_id} -> not MapSet.member?(binding_ids, ref_id) end) do
      nil ->
        :ok

      %{id: ref_id} ->
        dsl_error(
          module,
          path,
          "interaction #{inspect(id)} references unknown binding #{inspect(ref_id)}"
        )
    end
  end

  defp validate_payload_binding_refs(module, id, payload_mapping, context) do
    payload_mapping
    |> collect_binding_refs()
    |> validate_payload_binding_ref_list(
      module,
      id,
      context,
      [:signals, :interaction, id, :payload_mapping]
    )
  end

  defp validate_payload_binding_ref_list([], _module, _id, _context, _path), do: :ok

  defp validate_payload_binding_ref_list(refs, module, id, %{binding_ids: binding_ids}, path) do
    case Enum.find(refs, fn %{id: ref_id} -> not MapSet.member?(binding_ids, ref_id) end) do
      nil ->
        :ok

      %{id: ref_id} ->
        dsl_error(
          module,
          path,
          "interaction #{inspect(id)} payload mapping references unknown binding #{inspect(ref_id)}"
        )
    end
  end

  defp validate_node_signal_refs(module, nodes, context) do
    Enum.reduce_while(nodes, :ok, fn node, :ok ->
      with :ok <-
             validate_node_refs(
               module,
               node.kind,
               node.id,
               node.interaction_refs,
               context.interaction_ids,
               :interaction_refs
             ),
           :ok <-
             validate_node_refs(
               module,
               node.kind,
               node.id,
               node.binding_refs,
               context.binding_ids,
               :binding_refs
             ) do
        {:cont, :ok}
      else
        error -> {:halt, error}
      end
    end)
  end

  defp validate_node_refs(_module, _kind, _id, [], _ids, _field), do: :ok

  defp validate_node_refs(module, kind, id, refs, ids, field) do
    case Enum.find(refs, &(not MapSet.member?(ids, &1))) do
      nil ->
        :ok

      missing ->
        dsl_error(
          module,
          [:composition, kind, id],
          "#{kind} :#{id} #{field} must reference declared #{ref_kind(field)}, got #{inspect(missing)}"
        )
    end
  end

  defp theme_context(theme, context) do
    %{
      context
      | token_ids: theme_resource_ids(theme, context, &Theme.tokens/1),
        palette_ids: theme_resource_ids(theme, context, &Theme.palette_colors/1),
        role_ids: theme_resource_ids(theme, context, &Theme.semantic_roles/1)
    }
  end

  defp theme_resource_ids(theme, context, extractor) do
    theme
    |> theme_lineage(context)
    |> Enum.flat_map(fn current_theme -> current_theme |> extractor.() |> Enum.map(& &1.id) end)
    |> MapSet.new()
  end

  defp theme_lineage(theme, context) do
    do_theme_lineage(theme, context, MapSet.new())
  end

  defp do_theme_lineage(nil, _context, _visited), do: []

  defp do_theme_lineage(%Theme{} = theme, context, visited) do
    visited = MapSet.put(visited, theme.id)

    inherited =
      case Map.get(context.theme_by_id, theme.extends) do
        nil ->
          []

        %Theme{} = inherited_theme ->
          if MapSet.member?(visited, inherited_theme.id) do
            [inherited_theme]
          else
            do_theme_lineage(inherited_theme, context, visited)
          end
      end

    [theme | inherited]
  end

  defp flatten_nodes(nodes) do
    Enum.flat_map(nodes, fn %Node{children: children} = node ->
      [node | flatten_nodes(children)]
    end)
  end

  defp token_reference?(%{kind: :token_ref, path: path}) when is_list(path), do: true
  defp token_reference?(%{"kind" => :token_ref, "path" => path}) when is_list(path), do: true
  defp token_reference?(_other), do: false

  defp collect_binding_refs(values) when values in [%{}, []], do: []

  defp collect_binding_refs(values) when is_map(values) do
    values
    |> Enum.flat_map(fn
      {_key, %{kind: :binding_ref, id: id}} -> [Binding.ref(id)]
      {_key, %{"kind" => :binding_ref, "id" => id}} -> [Binding.ref(id)]
      {_key, nested} when is_map(nested) or is_list(nested) -> collect_binding_refs(nested)
      {_key, _value} -> []
    end)
  end

  defp collect_binding_refs(values) when is_list(values) do
    Enum.flat_map(values, fn
      %{kind: :binding_ref, id: id} -> [Binding.ref(id)]
      %{"kind" => :binding_ref, "id" => id} -> [Binding.ref(id)]
      nested when is_map(nested) or is_list(nested) -> collect_binding_refs(nested)
      _value -> []
    end)
  end

  defp find_renderer_local_key(values) when is_map(values) do
    values
    |> Enum.find_value(fn {key, value} ->
      cond do
        key in @renderer_local_keys ->
          key

        is_map(value) or is_list(value) ->
          find_renderer_local_key(value)

        true ->
          nil
      end
    end)
  end

  defp find_renderer_local_key(values) when is_list(values) do
    Enum.find_value(values, fn
      {key, value} ->
        cond do
          key in @renderer_local_keys -> key
          is_map(value) or is_list(value) -> find_renderer_local_key(value)
          true -> nil
        end

      value when is_map(value) or is_list(value) ->
        find_renderer_local_key(value)

      _value ->
        nil
    end)
  end

  defp ref_kind(:interaction_refs), do: "interactions"
  defp ref_kind(:binding_refs), do: "bindings"

  defp dsl_error(module, path, message) do
    {:error, %Spark.Error.DslError{module: module, path: path, message: message}}
  end
end
