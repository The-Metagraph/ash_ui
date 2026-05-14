defmodule ElmUi.Runtime do
  @moduledoc """
  Shared runtime entrypoint for native and canonical `elm_ui` screens.
  """

  alias UnifiedIUR.Element
  alias ElmUi.{FrontendRuntime, ServerRuntime, Transport}

  @type validation_state :: :scaffold_ready

  @spec modules() :: [module()]
  def modules do
    [
      ElmUi.ServerRuntime,
      ElmUi.ServerRuntime.State,
      ElmUi.ServerRuntime.Navigation,
      ElmUi.ServerRuntime.ViewState,
      ElmUi.ServerRuntime.StyleResolver,
      ElmUi.FrontendRuntime,
      ElmUi.FrontendRuntime.Boot,
      ElmUi.FrontendRuntime.Bridge,
      ElmUi.FrontendRuntime.StyleRealization
    ]
  end

  @spec capabilities() :: [atom()]
  def capabilities do
    [
      :native_mount,
      :canonical_mount,
      :frontend_hydration,
      :transport_translation,
      :frontend_event_flow,
      :boundary_envelope_flow,
      :style_resolution,
      :style_realization
    ]
  end

  @spec assumptions() :: map()
  def assumptions do
    %{
      server_authoritative: true,
      bounded_frontend_state: true,
      shared_runtime_for_native_and_canonical: true,
      frontend_asset_root: "assets/src"
    }
  end

  @spec validation_state() :: validation_state()
  def validation_state, do: :scaffold_ready

  @spec mount_native_screen(map(), keyword()) ::
          {:ok, ElmUi.ServerRuntime.State.t()} | {:error, ElmUi.ServerRuntime.Error.t()}
  def mount_native_screen(screen, opts \\ []) do
    ServerRuntime.mount_native_screen(screen, opts)
  end

  @spec mount_iur_screen(Element.t(), keyword()) ::
          {:ok, ElmUi.ServerRuntime.State.t()} | {:error, ElmUi.ServerRuntime.Error.t()}
  def mount_iur_screen(%Element{} = element, opts \\ []) do
    ServerRuntime.mount_iur_screen(element, opts)
  end

  @spec hydrate_frontend(ElmUi.ServerRuntime.State.t()) ::
          {:ok, ElmUi.FrontendRuntime.Model.t()} | {:error, ElmUi.FrontendRuntime.Error.t()}
  def hydrate_frontend(runtime_state) do
    runtime_state
    |> ServerRuntime.frontend_payload()
    |> FrontendRuntime.hydrate()
  end

  @spec handle_native_event(ElmUi.ServerRuntime.State.t(), keyword() | map()) ::
          {:ok, ElmUi.ServerRuntime.State.t()} | {:error, ElmUi.ServerRuntime.Error.t()}
  def handle_native_event(runtime_state, attrs) do
    attrs =
      attrs
      |> Enum.into(%{})
      |> Map.put_new(:source_kind, runtime_state.source_kind)
      |> Map.put_new(:boundary_mode, runtime_state.boundary_mode)
      |> Map.put_new(:runtime_id, runtime_state.runtime_id)
      |> Map.put_new(:screen, runtime_state.screen_id)

    with {:ok, translation} <- Transport.from_native_event(attrs) do
      ServerRuntime.handle_event(runtime_state, translation)
    end
  end

  @spec handle_frontend_event(ElmUi.ServerRuntime.State.t(), map()) ::
          {:ok, ElmUi.ServerRuntime.State.t(), map()} | {:error, ElmUi.ServerRuntime.Error.t()}
  def handle_frontend_event(runtime_state, payload) when is_map(payload) do
    ServerRuntime.handle_frontend_event(runtime_state, payload)
  end

  @spec handle_boundary_envelope(ElmUi.ServerRuntime.State.t(), map()) ::
          {:ok, ElmUi.ServerRuntime.State.t(), map()} | {:error, ElmUi.ServerRuntime.Error.t()}
  def handle_boundary_envelope(runtime_state, envelope) when is_map(envelope) do
    ServerRuntime.handle_boundary_envelope(runtime_state, envelope)
  end
end
