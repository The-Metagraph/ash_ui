defmodule LiveUi.Runtime do
  @moduledoc """
  Package-facing entrypoint for the server-authoritative LiveView runtime.
  """

  alias LiveUi.Runtime.{BrowserBridge, CanonicalScreen, Navigation, ScreenComponent, State}
  alias Jido.Signal
  alias UnifiedIUR.Element

  @type capability ::
          :native_mount
          | :native_render
          | :event_handling
          | :browser_bridge_placeholders
          | :canonical_boundary_events
          | :channel_transport

  @spec capabilities() :: [capability()]
  def capabilities do
    [
      :native_mount,
      :native_render,
      :event_handling,
      :browser_bridge_placeholders,
      :canonical_boundary_events,
      :channel_transport
    ]
  end

  @spec mount(module(), keyword()) :: {:ok, State.t()} | {:error, LiveUi.Runtime.Error.t()}
  def mount(screen, opts \\ []) do
    State.mount(screen, opts)
  end

  @spec mount_iur(Element.t(), keyword()) :: {:ok, State.t()} | {:error, LiveUi.Runtime.Error.t()}
  def mount_iur(%Element{} = element, opts \\ []) do
    canonical_assigns =
      opts
      |> Keyword.get(:assigns, %{})
      |> Map.put(:iur, element)

    CanonicalScreen
    |> State.mount(Keyword.merge(opts, assigns: canonical_assigns, mode: :canonical))
  end

  @spec handle_event(State.t(), String.t(), map()) ::
          {:ok, State.t()} | {:error, LiveUi.Runtime.Error.t()}
  def handle_event(runtime_state, event, payload) do
    State.handle_event(runtime_state, event, payload)
  end

  @spec dispatch_native_event(State.t(), String.t(), map(), keyword()) ::
          {:ok, State.t(), map()} | {:error, term()}
  def dispatch_native_event(%State{} = runtime_state, event, payload, opts \\ [])
      when is_binary(event) and is_map(payload) do
    attrs =
      opts
      |> Map.new()
      |> Map.put_new(:event, event)
      |> Map.put_new(:runtime_event, event)
      |> Map.put_new(:screen, State.screen_id(runtime_state))
      |> Map.put_new(:mode, runtime_state.mode)
      |> Map.put_new(:payload, payload)

    with {:ok, translation} <- LiveUi.Transport.translate_native(attrs),
         {:ok, updated_state} <- State.handle_runtime_action(runtime_state, translation) do
      {:ok, updated_state, translation}
    end
  end

  @spec handle_boundary_signal(State.t(), Signal.t() | map()) ::
          {:ok, State.t(), map()} | {:error, term()}
  def handle_boundary_signal(%State{} = runtime_state, signal) do
    with {:ok, runtime_action} <- LiveUi.Transport.decode_boundary_signal(signal),
         {:ok, updated_state} <- State.handle_runtime_action(runtime_state, runtime_action) do
      {:ok, updated_state, runtime_action}
    end
  end

  @spec handle_hook_event(State.t(), BrowserBridge.hook(), map(), keyword()) ::
          {:ok, State.t(), map()} | {:error, term()}
  def handle_hook_event(%State{} = runtime_state, hook, payload, opts \\ [])
      when is_atom(hook) and is_map(payload) do
    with {:ok, normalized_payload} <- BrowserBridge.normalize_payload(hook, payload) do
      dispatch_native_event(
        runtime_state,
        Keyword.get(opts, :event, "hook:" <> Atom.to_string(hook)),
        normalized_payload,
        Keyword.put(opts, :hook, hook)
      )
    end
  end

  @spec channel_envelope(Signal.t() | map(), keyword()) :: {:ok, map()} | {:error, term()}
  def channel_envelope(signal, opts \\ []) do
    LiveUi.Transport.Channel.outbound(signal, opts)
  end

  @spec handle_channel_envelope(State.t(), map()) :: {:ok, State.t(), map()} | {:error, term()}
  def handle_channel_envelope(%State{} = runtime_state, envelope) when is_map(envelope) do
    with {:ok, signal} <- LiveUi.Transport.Channel.inbound(envelope) do
      handle_boundary_signal(runtime_state, signal)
    end
  end

  @spec modules() :: [module()]
  def modules do
    [State, Navigation, ScreenComponent, BrowserBridge, CanonicalScreen, LiveUi.Transport.Channel]
  end

  @spec assumptions() :: map()
  def assumptions do
    %{
      server_authoritative?: true,
      browser_bridge_authoritative?: false,
      shared_runtime_for_native_and_iur?: true
    }
  end

  @spec validation_state() :: map()
  def validation_state do
    %{
      mount: :ready,
      event_routing: :ready,
      live_component_host: :ready,
      canonical_renderer: :advanced_ready,
      advanced_diagnostics: :ready,
      canonical_transport: :ready
    }
  end

  @spec component() :: module()
  def component, do: ScreenComponent

  @spec browser_bridge() :: module()
  def browser_bridge, do: BrowserBridge

  @spec namespace() :: module()
  def namespace, do: __MODULE__
end
