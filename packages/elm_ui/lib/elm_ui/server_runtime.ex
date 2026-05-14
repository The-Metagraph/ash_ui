defmodule ElmUi.ServerRuntime do
  @moduledoc """
  Authoritative Phoenix-side runtime scaffold for `elm_ui`.
  """

  alias UnifiedIUR.Element

  alias ElmUi.ServerRuntime.{
    Error,
    EventRouter,
    Navigation,
    RenderModel,
    State,
    StyleResolver,
    SyncBoundary,
    ViewState
  }

  alias ElmUi.Widget

  @spec modules() :: [module()]
  def modules do
    [
      __MODULE__,
      State,
      Navigation,
      ViewState,
      RenderModel,
      StyleResolver,
      EventRouter,
      SyncBoundary,
      Error
    ]
  end

  @spec mount_native_screen(map(), keyword()) :: {:ok, State.t()} | {:error, Error.t()}
  def mount_native_screen(screen, opts \\ []) do
    with :ok <- validate_screen(screen) do
      {:ok, build_state(:native, screen, nil, opts)}
    end
  end

  @spec mount_iur_screen(Element.t(), keyword()) :: {:ok, State.t()} | {:error, Error.t()}
  def mount_iur_screen(%Element{} = element, opts \\ []) do
    with {:ok, root} <- ElmUi.Renderer.render(element) do
      screen = %{
        id: element.id || "canonical-screen",
        title: Keyword.get(opts, :title, "Canonical Screen"),
        root: root,
        metadata: %{
          source: :canonical,
          bridge: :phoenix_elm,
          theme: Keyword.get(opts, :theme, :default)
        }
      }

      {:ok, build_state(:canonical, screen, element, opts)}
    else
      {:error, error} ->
        {:error,
         Error.new(:invalid_canonical_screen, error.message, %{
           renderer_code: error.code,
           renderer_details: error.details
         })}
    end
  end

  @spec frontend_payload(State.t()) :: map()
  def frontend_payload(%State{} = state) do
    ViewState.to_frontend_payload(state)
  end

  @spec frontend_envelope(State.t()) :: map()
  def frontend_envelope(%State{} = state) do
    SyncBoundary.hydration_envelope(state)
  end

  @spec receive_frontend_message(State.t(), map()) :: {:ok, map()} | {:error, Error.t()}
  def receive_frontend_message(%State{} = state, payload) do
    SyncBoundary.receive_frontend_message(state, payload)
  end

  @spec handle_frontend_event(State.t(), map()) :: {:ok, State.t(), map()} | {:error, Error.t()}
  def handle_frontend_event(%State{} = state, payload) do
    with {:ok, message} <- SyncBoundary.receive_frontend_message(state, payload),
         {:ok, translation} <- SyncBoundary.translation_for_message(state, message),
         {:ok, next_state} <- handle_event(state, translation) do
      {:ok, next_state, SyncBoundary.acknowledgement_envelope(next_state, translation)}
    end
  end

  @spec handle_boundary_envelope(State.t(), map()) ::
          {:ok, State.t(), map()} | {:error, Error.t()}
  def handle_boundary_envelope(%State{} = state, envelope) when is_map(envelope) do
    with {:ok, signal} <- ElmUi.Transport.Bridge.inbound_boundary_envelope(envelope),
         {:ok, translation} <- ElmUi.Transport.from_boundary_signal(signal),
         {:ok, next_state} <- handle_event(state, translation) do
      {:ok, next_state, SyncBoundary.acknowledgement_envelope(next_state, translation)}
    else
      {:error, %Error{} = error} ->
        {:error, error}

      {:error, %ElmUi.Transport.Error{} = error} ->
        {:error,
         Error.new(:invalid_boundary_envelope, error.message, %{
           reason: error.reason,
           transport_details: error.details
         })}

      {:error, reason} ->
        {:error,
         Error.new(:invalid_boundary_envelope, "Unable to route boundary envelope", %{
           reason: reason
         })}
    end
  end

  @spec handle_event(State.t(), map()) :: {:ok, State.t()} | {:error, Error.t()}
  def handle_event(%State{} = state, translation) do
    with {:ok, route} <- EventRouter.route(state, translation) do
      apply_route(state, route)
    end
  end

  defp validate_screen(%{id: _id, title: _title, root: %Widget{}}), do: :ok

  defp validate_screen(_screen) do
    {:error,
     Error.new(
       :invalid_screen,
       "Expected a native screen with id, title, and ElmUi.Widget root"
     )}
  end

  defp build_state(source_kind, screen, canonical_element, opts) do
    metadata =
      screen
      |> Map.get(:metadata, %{})
      |> Map.put(
        :theme,
        Keyword.get(opts, :theme, Map.get(Map.get(screen, :metadata, %{}), :theme, :default))
      )

    %State{
      runtime_id: Keyword.get(opts, :runtime_id, "web-ui-runtime"),
      source_kind: source_kind,
      title: screen.title,
      screen_id: screen.id,
      rendered_tree: screen.root,
      canonical_element: canonical_element,
      boundary_mode: if(source_kind == :canonical, do: :canonical_boundary, else: :native_local),
      diagnostics: [],
      event_log: [],
      navigation: Navigation.initialize(source_kind, screen, canonical_element, opts),
      metadata: metadata
    }
  end

  defp apply_route(%State{} = state, %{route: :local_runtime, family: family}) do
    {:ok, State.record_event(state, %{mode: :local, family: family})}
  end

  defp apply_route(%State{} = state, %{
         route: :canonical_boundary,
         family: family,
         translation: translation
       }) do
    {:ok,
     state
     |> State.record_event(%{mode: :boundary, family: family})
     |> State.record_boundary_signal(translation.signal)}
  end

  defp apply_route(%State{} = state, %{
         route: :navigation_transition,
         family: family,
         translation: translation
       }) do
    with {:ok, next_state} <- Navigation.apply_transition(state, translation) do
      next_state =
        next_state
        |> State.record_event(%{
          mode: if(translation.boundary == :boundary, do: :boundary, else: :local),
          family: family
        })
        |> maybe_record_boundary_signal(translation)

      {:ok, next_state}
    end
  end

  defp maybe_record_boundary_signal(%State{} = state, %{signal: signal})
       when not is_nil(signal) do
    State.record_boundary_signal(state, signal)
  end

  defp maybe_record_boundary_signal(%State{} = state, _translation), do: state
end
