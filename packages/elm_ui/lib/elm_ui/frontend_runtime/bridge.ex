defmodule ElmUi.FrontendRuntime.Bridge do
  @moduledoc """
  Browser bridge helpers for outgoing interaction envelopes.
  """

  alias ElmUi.FrontendRuntime.{Boot, Error, Message, Model, Realization}
  alias ElmUi.Transport

  @spec dispatch_interaction(Model.t(), keyword() | map()) ::
          {:ok, Model.t(), map()} | {:error, Error.t() | term()}
  def dispatch_interaction(%Model{} = model, attrs) do
    with {:ok, translation} <- translate_interaction(model, attrs) do
      updated_model = apply_outgoing_translation(model, translation)
      {:ok, updated_model, ElmUi.Transport.Bridge.event_message(model, translation)}
    end
  end

  @spec outgoing_interaction(Model.t(), keyword() | map()) :: {:ok, map()} | {:error, term()}
  def outgoing_interaction(%Model{} = model, attrs) do
    with {:ok, translation} <- translate_interaction(model, attrs) do
      {:ok, ElmUi.Transport.Bridge.event_message(model, translation)}
    end
  end

  @spec apply_server_message(Model.t(), map()) :: {:ok, Model.t()} | {:error, Error.t()}
  def apply_server_message(%Model{} = model, payload) do
    with {:ok, %{kind: kind} = message} <- Message.from_payload(payload) do
      case kind do
        :ack ->
          {:ok, apply_acknowledgement(model, message)}

        :hydrate ->
          Boot.hydrate_message(message)

        other ->
          {:error,
           Error.new(:unsupported_server_message, "Unsupported server message kind", %{
             kind: other
           })}
      end
    else
      {:error, reason} ->
        {:error,
         Error.new(:unsupported_server_message, "Invalid server message", %{reason: reason})}
    end
  end

  @spec incoming_message(map()) :: {:ok, Message.t()} | {:error, term()}
  def incoming_message(payload) do
    Message.from_payload(payload)
  end

  defp translate_interaction(%Model{} = model, attrs) do
    attrs =
      attrs
      |> Enum.into(%{})
      |> Map.put_new(:screen, model.screen_id || model.title)
      |> Map.put_new(:runtime_id, model.runtime_id)
      |> Map.put_new(:source_kind, model.source_kind)
      |> Map.put_new(:boundary_mode, model.boundary_mode)
      |> maybe_put_metadata(model)

    Transport.from_native_event(attrs)
  end

  defp apply_outgoing_translation(%Model{} = model, translation) do
    local_state =
      model.local_state
      |> maybe_track_focus(translation)
      |> maybe_track_editing(translation)
      |> put_feedback_state(translation)

    %{model | local_state: local_state, tree: Realization.realize(model.render_tree, local_state)}
  end

  defp maybe_track_focus(local_state, %{widget_id: widget_id}) when not is_nil(widget_id) do
    Map.put(local_state, :focused_id, widget_id)
  end

  defp maybe_track_focus(local_state, _translation), do: local_state

  defp maybe_track_editing(local_state, %{family: :change, widget_id: widget_id})
       when not is_nil(widget_id) do
    editing_ids =
      local_state
      |> Map.get(:editing_ids, [])
      |> Kernel.++([widget_id])
      |> Enum.uniq()

    Map.put(local_state, :editing_ids, editing_ids)
  end

  defp maybe_track_editing(local_state, _translation), do: local_state

  defp put_feedback_state(
         local_state,
         %{frontend_update: %{mode: :bounded_local_feedback}} = translation
       ) do
    local_state
    |> Map.delete(:pending_boundary_event)
    |> Map.put(:flash, %{
      family: translation.family,
      intent: translation.intent,
      scope: :local_feedback
    })
  end

  defp put_feedback_state(local_state, %{frontend_update: %{mode: :server_sync}} = translation) do
    local_state
    |> Map.put(:pending_boundary_event, %{
      family: translation.family,
      intent: translation.intent,
      runtime_event: translation.runtime_event
    })
    |> Map.put(:flash, %{
      family: translation.family,
      intent: translation.intent,
      scope: :pending_server_sync
    })
  end

  defp put_feedback_state(local_state, _translation), do: local_state

  defp apply_acknowledgement(%Model{} = model, %{payload: payload}) do
    payload = Map.new(payload)

    local_state =
      model.local_state
      |> Map.delete(:pending_boundary_event)
      |> Map.put(:last_server_ack, payload)
      |> Map.put(:flash, %{
        family: Map.get(payload, :family) || Map.get(payload, "family"),
        intent: Map.get(payload, :intent) || Map.get(payload, "intent"),
        scope: :server_ack
      })

    diagnostics =
      case Map.get(payload, :diagnostics) || Map.get(payload, "diagnostics") do
        diagnostics when is_list(diagnostics) -> diagnostics
        _ -> model.diagnostics
      end

    model
    |> apply_authoritative_screen(payload)
    |> Map.put(:local_state, local_state)
    |> Map.put(:tree, Realization.realize(model.render_tree, local_state))
    |> Map.put(:diagnostics, diagnostics)
  end

  defp apply_authoritative_screen(%Model{} = model, payload) do
    case Map.get(payload, :authoritative_screen) || Map.get(payload, "authoritative_screen") do
      authoritative_screen when is_map(authoritative_screen) ->
        authoritative_screen = Map.new(authoritative_screen)

        render_tree =
          Map.get(authoritative_screen, :tree) || Map.get(authoritative_screen, "tree")

        %{
          model
          | screen_id:
              Map.get(authoritative_screen, :screen_id) ||
                Map.get(authoritative_screen, "screen_id") || model.screen_id,
            title:
              Map.get(authoritative_screen, :title) || Map.get(authoritative_screen, "title") ||
                model.title,
            source_kind:
              Map.get(authoritative_screen, :source_kind) ||
                Map.get(authoritative_screen, "source_kind") || model.source_kind,
            boundary_mode:
              Map.get(authoritative_screen, :boundary_mode) ||
                Map.get(authoritative_screen, "boundary_mode") || model.boundary_mode,
            render_tree: render_tree || model.render_tree,
            metadata:
              Map.get(authoritative_screen, :metadata) ||
                Map.get(authoritative_screen, "metadata") || model.metadata
        }

      _other ->
        model
    end
  end

  defp maybe_put_metadata(attrs, model) do
    metadata =
      attrs
      |> Map.get(:metadata, Map.get(attrs, "metadata", %{}))
      |> normalize_map()
      |> maybe_put(:route_state, Map.get(attrs, :route_state) || Map.get(attrs, "route_state"))
      |> maybe_put(:screen_id, model.screen_id)

    Map.put(attrs, :metadata, metadata)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp normalize_map(map) when is_map(map), do: Map.new(map)
  defp normalize_map(list) when is_list(list), do: Enum.into(list, %{})
  defp normalize_map(_other), do: %{}
end
