defmodule AshUI.LiveView.Integration do
  @moduledoc """
  LiveView integration layer for Ash UI screens.

  This module provides helpers and callbacks for integrating Ash UI screens
  with Phoenix LiveView, handling mount, update, and event handling.
  """

  require Logger
  require Ash.Query

  alias AshUI.Authorization.BindingPolicy
  alias AshUI.Authorization.Runtime
  alias AshUI.Compiler
  alias AshUI.Config
  alias AshUI.LiveView.BindingRuntime
  alias AshUI.LiveView.IURHydration
  alias AshUI.LiveView.UpdateIntegration
  alias AshUI.Rendering.CanonicalIUR
  alias AshUI.Rendering.IURAdapter
  alias AshUI.Runtime.BindingEvaluator
  alias AshUI.Telemetry

  @type screen_identifier :: String.t() | atom() | integer()
  @type mount_params :: map()
  @type mount_result :: {:ok, Phoenix.LiveView.Socket.t()} | {:error, term()}

  @doc """
  Mounts a UI screen in LiveView.

  Loads the screen resource, authorizes access, compiles to IUR,
  evaluates bindings, and assigns everything to the socket.

  ## Parameters
    * `socket` - LiveView socket
    * `screen_id` - Screen identifier (name, ID, or atom)
    * `params` - Optional parameters for screen loading

  ## Returns
    * `{:ok, socket}` - Screen mounted successfully
    * `{:error, reason}` - Mount failed

  ## Examples

      def mount(params, session, socket) do
        AshUI.LiveView.Integration.mount_ui_screen(socket, :dashboard, params)
      end
  """
  @spec mount_ui_screen(Phoenix.LiveView.Socket.t(), screen_identifier(), mount_params()) ::
          mount_result()
  def mount_ui_screen(socket, screen_id, params \\ %{}) do
    with {:ok, user} <- get_current_user(socket),
         {:ok, screen} <- load_screen(socket, screen_id, user, params),
         :ok <- authorize_screen(screen, user),
         {:ok, iur} <- compile_screen(screen, ui_storage: current_ui_storage(socket)),
         {:ok, bindings} <- evaluate_bindings(screen, socket, user, params, iur),
         socket <- assign_screen_state(socket, screen, iur, bindings, user, params),
         socket <- UpdateIntegration.sync_binding_subscriptions(socket) do
      {:ok, socket}
    else
      {:error, :unauthorized} ->
        {:error, :unauthorized}

      {:error, reason} ->
        Logger.error("Failed to mount screen #{inspect(screen_id)}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Authorizes screen access for a user.

  Checks the `:mount` action policy for the screen resource.

  ## Returns
    * `:ok` - Authorized
    * `{:error, :unauthorized}` - Not authorized
  """
  @spec authorize_screen(map(), term()) :: :ok | {:error, :unauthorized}
  def authorize_screen(screen, user) when is_map(screen) do
    case Runtime.check_mount_authorization(user, screen) do
      :authorized -> :ok
      _ -> {:error, :unauthorized}
    end
  end

  @doc """
  Compiles a screen resource to canonical IUR.

  ## Returns
    * `{:ok, iur}` - Compiled IUR structure
    * `{:error, reason}` - Compilation failed
  """
  @spec compile_screen(map(), keyword()) :: {:ok, map()} | {:error, term()}
  def compile_screen(screen, opts \\ [])

  def compile_screen(%{id: nil}, _opts), do: {:error, :invalid_screen}
  def compile_screen(%{name: nil}, _opts), do: {:error, :invalid_screen}

  def compile_screen(screen, opts) when is_map(screen) do
    with {:ok, iur} <- Compiler.compile(screen, opts),
         {:ok, canonical_iur} <- IURAdapter.to_canonical(iur) do
      {:ok, canonical_iur}
    end
  end

  @doc """
  Evaluates all bindings for a screen.

  Loads and evaluates all bindings associated with the screen
  and its elements.

  ## Returns
    * `{:ok, binding_values}` - Map of binding IDs to evaluated values
    * `{:error, reason}` - Evaluation failed
  """
  @spec evaluate_bindings(map(), Phoenix.LiveView.Socket.t(), term(), map(), map() | nil) ::
          {:ok, map()} | {:error, term()}
  def evaluate_bindings(screen, socket, user, params, compiled_iur \\ nil) when is_map(screen) do
    context = build_evaluation_context(socket, user, params)

    screen
    |> load_screen_bindings(user, socket, compiled_iur)
    |> evaluate_batch_bindings(context)
  end

  @doc """
  Applies the current binding state back onto the canonical IUR tree.
  """
  @spec hydrate_iur(map(), map()) :: map()
  def hydrate_iur(iur, bindings) when is_map(iur) and is_map(bindings) do
    IURHydration.hydrate(iur, bindings)
  end

  # Private functions

  defp get_current_user(socket) do
    case socket.assigns[:current_user] do
      nil -> {:error, :no_user}
      user -> {:ok, user}
    end
  end

  defp load_screen(socket, screen_id, user, params) do
    ui_storage = current_ui_storage(socket)

    case load_screen_by_identifier(screen_id, user, params, ui_storage) do
      {:ok, screen} -> {:ok, screen}
      {:error, :invalid_primary_key} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  defp load_screen_by_identifier(screen_id, user, params, ui_storage) when is_atom(screen_id) do
    load_screen_by_name(Atom.to_string(screen_id), user, params, ui_storage)
  end

  defp load_screen_by_identifier(screen_id, user, params, ui_storage) do
    case load_screen_by_primary_key(screen_id, user, params, ui_storage) do
      {:ok, nil} when is_binary(screen_id) ->
        load_screen_by_name(screen_id, user, params, ui_storage)

      {:ok, nil} ->
        {:error, :not_found}

      {:ok, _screen} = result ->
        result

      {:error, _reason} when is_binary(screen_id) ->
        load_screen_by_name(screen_id, user, params, ui_storage)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp load_screen_by_primary_key(screen_id, user, params, ui_storage) do
    screen_resource = Config.screen_resource(ui_storage)
    domain = Config.ui_storage_domain(ui_storage)

    query =
      screen_resource
      |> Ash.Query.new()
      |> Ash.Query.filter(id == ^screen_id)
      |> Ash.Query.for_read(:mount, %{
        user_id: get_user_id(user),
        params: params
      })

    case Ash.read_one(query, actor: user, domain: domain, authorize?: true) do
      {:ok, screen} -> {:ok, screen}
      {:error, reason} -> {:error, reason}
    end
  rescue
    Ash.Error.Invalid.InvalidPrimaryKey -> {:error, :invalid_primary_key}
    Ash.Error.Invalid.NoSuchResource -> {:error, :not_found}
  end

  defp load_screen_by_name(name, user, params, ui_storage) do
    screen_resource = Config.screen_resource(ui_storage)
    domain = Config.ui_storage_domain(ui_storage)

    query =
      screen_resource
      |> Ash.Query.new()
      |> Ash.Query.filter(name == ^name)
      |> Ash.Query.for_read(:mount, %{
        user_id: get_user_id(user),
        params: params
      })

    case Ash.read_one(query, actor: user, domain: domain, authorize?: true) do
      {:ok, %{__struct__: _} = screen} -> {:ok, screen}
      {:ok, nil} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  defp build_evaluation_context(socket, user, params) do
    ui_storage = current_ui_storage(socket)

    %{
      user_id: get_user_id(user),
      user: user,
      authorize?: true,
      params: params,
      assigns: socket.assigns,
      socket: socket,
      ui_storage: ui_storage,
      ash_domains:
        Map.get(
          socket.assigns,
          :ash_ui_domains,
          Config.runtime_domains(ui_storage)
        )
    }
  end

  defp get_user_id(user) do
    # Extract user ID from user struct/map
    case user do
      %{id: id} -> id
      user when is_binary(user) -> user
      _ -> nil
    end
  end

  defp load_screen_bindings(screen, user, socket, compiled_iur) when is_map(screen) do
    compiled_bindings = compiled_runtime_bindings(compiled_iur)

    if compiled_bindings != [] do
      Enum.map(compiled_bindings, &normalize_compiled_binding(&1, screen.id))
    else
      load_persisted_screen_bindings(screen, user, socket)
    end
  end

  defp compiled_runtime_bindings(nil), do: []
  defp compiled_runtime_bindings(%UnifiedIUR.Element{} = iur), do: CanonicalIUR.ash_bindings(iur)
  defp compiled_runtime_bindings(iur) when is_map(iur), do: Map.get(iur, "bindings", [])
  defp compiled_runtime_bindings(_iur), do: []

  defp load_persisted_screen_bindings(screen, user, socket) when is_map(screen) do
    ui_storage = current_ui_storage(socket)
    binding_resource = Config.binding_resource(ui_storage)
    domain = Config.ui_storage_domain(ui_storage)

    query =
      binding_resource
      |> Ash.Query.new()
      |> Ash.Query.filter(screen_id == ^screen.id)

    case Ash.read(query, actor: user, domain: domain, authorize?: true) do
      {:ok, bindings} ->
        bindings
        |> Enum.map(&Map.put(&1, :screen, screen))
        |> Enum.filter(&binding_readable?(&1, user))

      {:error, _} ->
        []
    end
  rescue
    _ -> []
  end

  defp evaluate_batch_bindings(bindings, context) when is_list(bindings) do
    results =
      Enum.reduce(bindings, %{}, fn binding, acc ->
        case BindingEvaluator.evaluate(binding, context) do
          {:ok, value} ->
            Map.put(
              acc,
              binding_identifier(binding),
              build_binding_state(binding, value: value, error: nil)
            )

          {:error, reason} ->
            Logger.warning(
              "Binding #{binding_identifier(binding)} evaluation failed: #{inspect(reason)}"
            )

            Map.put(
              acc,
              binding_identifier(binding),
              build_binding_state(binding, value: nil, error: reason)
            )
        end
      end)

    {:ok, results}
  end

  defp assign_screen_state(socket, screen, iur, bindings, user, params) do
    ui_storage = current_ui_storage(socket)

    socket
    |> Phoenix.Component.assign(:ash_ui_screen, screen)
    |> Phoenix.Component.assign(:ash_ui_base_iur, iur)
    |> Phoenix.Component.assign(:ash_ui_params, params)
    |> Phoenix.Component.assign(:ash_ui_storage, ui_storage)
    |> Phoenix.Component.assign(
      :ash_ui_domains,
      Map.get(socket.assigns, :ash_ui_domains, Config.runtime_domains(ui_storage))
    )
    |> Phoenix.Component.assign(:ash_ui_user, user)
    |> Phoenix.Component.assign(:ash_ui_loaded_at, DateTime.utc_now())
    |> BindingRuntime.assign(bindings)
  end

  @doc """
  Redirects to login page when authorization fails.

  ## Examples

      case authorize_screen(screen, user) do
        :ok -> {:ok, socket}
        {:error, :unauthorized} = error ->
          AshUI.LiveView.Integration.redirect_to_login(socket, error)
      end
  """
  @spec redirect_to_login(Phoenix.LiveView.Socket.t(), term()) :: {:error, term()}
  def redirect_to_login(_socket, _error) do
    # In production, would use Phoenix.LiveView.redirect/3
    # This is a placeholder for the redirect logic
    {:error, :unauthorized}
  end

  @doc """
  Emits telemetry events for screen operations.

  ## Events
    * `[:ash_ui, :screen, :mount]` - Screen mounted successfully
    * `[:ash_ui, :screen, :mount_error]` - Screen mount failed
    * `[:ash_ui, :screen, :auth_failure]` - Authorization failed

  ## Examples

      emit_telemetry(:mount, %{screen_id: screen.id}, %{})
  """
  def emit_telemetry(event, metadata, measurements \\ %{}) do
    Telemetry.emit(:screen, event, measurements, metadata)
  end

  defp build_binding_state(binding, attrs) do
    %{
      id: binding_identifier(binding),
      source: Map.get(binding, :source) || Map.get(binding, "source") || %{},
      target: Map.get(binding, :target) || Map.get(binding, "target"),
      binding_type: normalized_binding_type(binding),
      transform: Map.get(binding, :transform) || Map.get(binding, "transform") || %{},
      metadata: Map.get(binding, :metadata) || Map.get(binding, "metadata") || %{},
      screen_id: Map.get(binding, :screen_id) || Map.get(binding, "screen_id"),
      element_id: Map.get(binding, :element_id) || Map.get(binding, "element_id"),
      value: Keyword.get(attrs, :value),
      error: Keyword.get(attrs, :error),
      updated_at: System.system_time(:millisecond)
    }
  end

  defp binding_readable?(binding, user) do
    BindingPolicy.can_read?(user, binding)
  end

  defp current_ui_storage(socket) do
    overrides =
      case socket do
        %Phoenix.LiveView.Socket{} = socket -> Map.get(socket.assigns, :ash_ui_storage)
        _ -> nil
      end

    Config.ui_storage(overrides)
  end

  defp normalize_compiled_binding(binding, screen_id) do
    binding
    |> Map.put_new("screen_id", screen_id)
    |> Map.put_new(
      "binding_type",
      case Map.get(binding, "type") do
        "event" -> :action
        "collection" -> :list
        _ -> :value
      end
    )
  end

  defp binding_identifier(binding) do
    Map.get(binding, :id) || Map.get(binding, "id")
  end

  defp normalized_binding_type(binding) do
    case Map.get(binding, :binding_type) || Map.get(binding, "binding_type") ||
           Map.get(binding, "type") do
      :value -> :value
      "value" -> :value
      :action -> :action
      "action" -> :action
      "event" -> :action
      :list -> :list
      "list" -> :list
      "collection" -> :list
      other when is_atom(other) -> other
      _ -> :value
    end
  end
end
