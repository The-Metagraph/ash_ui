defmodule AshUI.LiveView.EventHandler do
  @moduledoc """
  LiveView event handling integration for Ash UI.

  Routes UI events to appropriate handlers, processes value changes,
  and executes Ash actions triggered by UI interactions.
  """

  require Logger

  alias AshUI.Config
  alias AshUI.LiveView.BindingRuntime
  alias AshUI.LiveView.UpdateIntegration
  alias AshUI.Runtime.ActionBinding
  alias AshUI.Runtime.BidirectionalBinding
  alias AshUI.Runtime.Navigation

  @type event_result ::
          {:noreply, Phoenix.LiveView.Socket.t()} | {:reply, map(), Phoenix.LiveView.Socket.t()}

  @doc """
  Handles UI events and routes them to appropriate handlers.

  This is the main entry point for UI events from LiveView.
  Events are parsed and routed based on their target and type.

  ## Parameters
    * `event_name` - The name of the event (e.g., "ash_ui_event")
    * `event_params` - Event parameters from the UI
    * `socket` - LiveView socket

  ## Returns
    * `{:noreply, socket}` - Event handled, no reply needed
    * `{:reply, map(), socket}` - Event handled with reply data

  ## Examples

      def handle_event("ash_ui_event", params, socket) do
        AshUI.LiveView.EventHandler.handle_event("ash_ui_event", params, socket)
      end
  """
  @spec handle_event(String.t(), map(), Phoenix.LiveView.Socket.t()) :: event_result()
  def handle_event(event_name, event_params, socket) do
    with {:ok, event} <- parse_event(event_name, event_params),
         {:ok, socket} <- route_event(event, socket) do
      {:noreply, socket}
    else
      {:error, reason} ->
        Logger.error("Event handling failed: #{inspect(reason)}")
        socket = assign_flash(socket, :error, "Action failed: #{inspect(reason)}")
        {:noreply, socket}
    end
  end

  @doc """
  Handles value change events from form elements.

  Processes `phx-blur` or `phx-change` events and updates
  bound Ash resources.

  ## Examples

      def handle_event("ash_ui_change", params, socket) do
        AshUI.LiveView.EventHandler.handle_value_change(params, socket)
      end
  """
  @spec handle_value_change(map(), Phoenix.LiveView.Socket.t()) :: event_result()
  def handle_value_change(event_params, socket) do
    binding_id = Map.get(event_params, "binding_id")
    target = Map.get(event_params, "target")
    element_id = Map.get(event_params, "element_id")
    value = extract_value(event_params)

    with {:ok, binding} <- find_value_binding(binding_id, target, element_id, socket),
         context <- build_event_context(socket, binding),
         {:ok, socket} <- write_value(binding, value, socket, context),
         {:noreply, refreshed_socket} <- refresh_bindings(socket) do
      {:noreply, refreshed_socket}
    else
      {:error, reason, error_socket} ->
        Logger.error("Value change failed: #{inspect(reason)}")
        socket = assign_flash(error_socket, :error, "Update failed: #{inspect(reason)}")
        {:noreply, socket}

      {:error, reason} ->
        Logger.error("Value change failed: #{inspect(reason)}")
        socket = assign_flash(socket, :error, "Update failed: #{inspect(reason)}")
        {:noreply, socket}
    end
  end

  @doc """
  Handles action events from buttons and other triggers.

  Processes `phx-click` events and executes bound Ash actions.

  ## Examples

      def handle_event("ash_ui_action", params, socket) do
        AshUI.LiveView.EventHandler.handle_action_event(params, socket)
      end
  """
  @spec handle_action_event(map(), Phoenix.LiveView.Socket.t()) :: event_result()
  def handle_action_event(event_params, socket) do
    action_id = Map.get(event_params, "action_id")
    element_id = Map.get(event_params, "element_id")
    signal = Map.get(event_params, "signal")
    event_data = extract_action_event_data(event_params)

    with {:ok, binding} <- find_action_binding(action_id, element_id, signal, socket),
         context <- build_event_context(socket, binding),
         {:ok, result} <- execute_action(binding, event_data, socket, context),
         socket <- handle_action_result(result, socket) do
      {:reply, %{status: :ok}, socket}
    else
      {:error, :unauthorized} ->
        socket = assign_flash(socket, :error, "You are not authorized to perform this action")
        {:reply, %{status: :error, reason: "unauthorized"}, socket}

      {:error, :binding_not_found} ->
        handle_navigation_event(event_params, socket)

      {:error, reason} ->
        Logger.error("Action execution failed: #{inspect(reason)}")
        socket = assign_flash(socket, :error, "Action failed: #{inspect(reason)}")
        {:reply, %{status: :error, reason: inspect(reason)}, socket}
    end
  end

  @doc """
  Parses a UI event into a structured format.

  ## Event Format
    * `target` - The UI element that triggered the event
    * `type` - The event type (change, click, submit, etc.)
    * `data` - Event data from the UI

  ## Returns
    * `{:ok, event}` - Successfully parsed
    * `{:error, :invalid_event}` - Invalid event format
  """
  @spec parse_event(String.t(), map()) :: {:ok, map()} | {:error, :invalid_event}
  def parse_event(event_name, event_params) do
    case extract_event_type(event_name) do
      {:ok, type} ->
        {:ok,
         %{
           type: type,
           target: Map.get(event_params, "target"),
           data: Map.get(event_params, "data", %{}),
           params: event_params
         }}

      :error ->
        {:error, :invalid_event}
    end
  end

  @doc """
  Routes an event to the appropriate handler based on type.

  ## Event Types
    * `:change` - Value change, routes to `handle_value_change/2`
    * `:click` - Button click, routes to `handle_action_event/2`
    * `:submit` - Form submit, routes to `handle_action_event/2`
  """
  @spec route_event(map(), Phoenix.LiveView.Socket.t()) ::
          {:ok, Phoenix.LiveView.Socket.t()} | {:error, term()}
  def route_event(%{type: :change} = event, socket) do
    params = Map.merge(event.data, %{"target" => event.target, "signal" => "change"})

    handle_value_change(params, socket)
    |> wrap_route_result()
  end

  def route_event(%{type: :click} = event, socket) do
    params = Map.merge(event.data, %{"action_id" => event.target, "signal" => "click"})

    handle_action_event(params, socket)
    |> wrap_route_result()
  end

  def route_event(%{type: :submit} = event, socket) do
    params = Map.merge(event.data, %{"action_id" => event.target, "signal" => "submit"})

    handle_action_event(params, socket)
    |> wrap_route_result()
  end

  def route_event(%{type: type}, _socket) do
    {:error, {:unknown_event_type, type}}
  end

  @doc """
  Validates event data before processing.

  ## Returns
    * `:ok` - Valid event data
    * `{:error, reason}` - Invalid event data
  """
  @spec validate_event_data(map(), String.t()) :: :ok | {:error, term()}
  def validate_event_data(event_data, expected_type) do
    with :ok <- validate_required_fields(event_data),
         :ok <- validate_event_type(event_data, expected_type) do
      :ok
    end
  end

  @doc """
  Handles validation errors from event processing.

  Displays errors to the user and logs them for debugging.

  ## Examples

      case validate_event_data(data, "change") do
        :ok -> # proceed
        {:error, reason} -> EventHandler.handle_validation_error(reason, socket)
      end
  """
  @spec handle_validation_error(term(), Phoenix.LiveView.Socket.t()) :: event_result()
  def handle_validation_error(reason, socket) do
    Logger.warning("Validation error: #{inspect(reason)}")

    error_message =
      case reason do
        :missing_target -> "Missing target element"
        :missing_data -> "Missing required data"
        {:invalid_type, got, expected} -> "Invalid event type: expected #{expected}, got #{got}"
        _ -> "Validation failed"
      end

    socket = assign_flash(socket, :error, error_message)
    {:noreply, socket}
  end

  # Private functions

  defp extract_event_type("ash_ui_action"), do: {:ok, :submit}
  defp extract_event_type("ash_ui_change"), do: {:ok, :change}
  defp extract_event_type("ash_ui_click"), do: {:ok, :click}
  defp extract_event_type("ash_ui_submit"), do: {:ok, :submit}
  defp extract_event_type(_), do: :error

  defp wrap_route_result({:noreply, socket}), do: {:ok, socket}
  defp wrap_route_result({:reply, _data, socket}), do: {:ok, socket}

  defp find_value_binding(binding_id, _target, element_id, socket) when is_binary(binding_id) do
    case socket
         |> candidate_value_bindings(element_id)
         |> find_binding_by_id(binding_id) do
      {:ok, binding} ->
        if owner_element_matches?(binding, element_id) do
          {:ok, binding}
        else
          {:error, :binding_not_found}
        end

      error ->
        error
    end
  end

  defp find_value_binding(_binding_id, target, element_id, socket) do
    socket
    |> candidate_value_bindings(element_id)
    |> find_binding_by_target(target, element_id)
  end

  defp candidate_value_bindings(socket, nil) do
    screen_bindings = screen_bindings(socket)
    element_bindings = element_bindings(socket)
    Map.merge(screen_bindings, element_bindings)
  end

  defp candidate_value_bindings(socket, _element_id) do
    element_bindings(socket)
  end

  defp find_binding_by_id(bindings, binding_id) do
    atom_binding_id = safe_to_existing_atom(binding_id)

    case Map.get(bindings, binding_id) ||
           (atom_binding_id && Map.get(bindings, atom_binding_id)) ||
           Enum.find_value(bindings, fn {_key, binding} ->
             if Map.get(binding, :id) == binding_id or Map.get(binding, "id") == binding_id do
               binding
             end
           end) do
      nil -> {:error, :binding_not_found}
      binding -> {:ok, binding}
    end
  end

  defp find_binding_by_target(bindings, target, element_id) do
    case Enum.find(bindings, fn {_id, binding} ->
           binding_target(binding) == target and owner_element_matches?(binding, element_id)
         end) do
      {id, binding} ->
        binding =
          binding
          |> Map.put_new(:id, id)
          |> Map.put_new(:target, target)

        {:ok, binding}

      nil ->
        {:error, :binding_not_found}
    end
  end

  defp find_action_binding(action_id, element_id, signal, socket) do
    bindings = action_bindings(socket)

    case find_binding_by_id(bindings, action_id) do
      {:ok, binding} ->
        if owner_element_matches?(binding, element_id) and signal_matches?(binding, signal) do
          {:ok, binding}
        else
          {:error, :binding_not_found}
        end

      {:error, :binding_not_found} ->
        {:error, :binding_not_found}
    end
  end

  defp build_event_context(socket, binding) do
    ui_storage = Map.get(socket.assigns, :ash_ui_storage)
    binding_metadata = if is_map(binding), do: binding_metadata(binding), else: %{}

    %{
      user_id: get_user_id(socket),
      user: socket.assigns[:ash_ui_user],
      authorize?: true,
      params: socket.assigns[:ash_ui_params] || %{},
      assigns: socket.assigns,
      binding_values: extract_binding_values(socket),
      binding_owner: %{
        scope: BindingRuntime.owner_scope(binding || %{}),
        module: Map.get(binding_metadata, "owner_module"),
        element_id: BindingRuntime.owner_element_id(binding || %{}),
        signal: BindingRuntime.owner_signal(binding || %{})
      },
      socket: socket,
      ui_storage: Config.ui_storage(ui_storage),
      ash_domains: Map.get(socket.assigns, :ash_ui_domains, Config.runtime_domains(ui_storage))
    }
  end

  defp get_user_id(socket) do
    case socket.assigns[:ash_ui_user] do
      %{id: id} -> id
      _ -> nil
    end
  end

  defp write_value(binding, value, socket, context) do
    case BidirectionalBinding.write_binding(binding, value, socket, context) do
      {:ok, updated_socket, _result} -> {:ok, updated_socket}
      {:error, reason, error_socket} -> {:error, reason, error_socket}
    end
  end

  defp execute_action(binding, event_data, _socket, context) do
    executor =
      if BindingRuntime.action_binding?(binding) and
           BindingRuntime.owner_scope(binding) == :element do
        &ActionBinding.execute_declared_action/3
      else
        &ActionBinding.execute_action/3
      end

    case executor.(binding, event_data, context) do
      {:ok, result} -> {:ok, result}
      {:error, %{errors: [%{"message" => "Unauthorized"} | _]}} -> {:error, :unauthorized}
      {:error, reason} -> {:error, reason}
    end
  end

  defp handle_navigation_event(event_params, socket) do
    case Navigation.handle_event(event_params, socket) do
      {:ok, result, socket} ->
        {:reply, %{status: :ok, navigation: result.transport_summary}, socket}

      {:error, :navigation_interaction_not_found} ->
        socket = assign_flash(socket, :error, "Action failed: binding_not_found")
        {:reply, %{status: :error, reason: "binding_not_found"}, socket}

      {:error, reason} ->
        Logger.error("Navigation execution failed: #{inspect(reason)}")
        socket = assign_flash(socket, :error, "Navigation failed: #{inspect(reason)}")
        {:reply, %{status: :error, reason: inspect(reason)}, socket}
    end
  end

  defp handle_action_result(result, socket) do
    case result.status do
      :ok ->
        socket = assign_flash(socket, :info, "Action completed successfully")
        socket

      :error ->
        socket = assign_flash(socket, :error, result.message || "Action failed")
        socket
    end
  end

  defp assign_flash(socket, type, message) do
    flash = Map.get(socket.assigns, :flash, %{})
    updated_flash = Map.put(flash, type, message)
    %{socket | assigns: Map.put(socket.assigns, :flash, updated_flash)}
  end

  defp validate_required_fields(event_data) do
    required = ["target", "data"]
    missing = Enum.reject(required, &Map.has_key?(event_data, &1))

    if missing == [] do
      :ok
    else
      {:error, {:missing_fields, missing}}
    end
  end

  defp validate_event_type(_event_data, _expected_type) do
    # Additional type-specific validation
    :ok
  end

  defp safe_to_existing_atom(value) when is_binary(value) do
    String.to_existing_atom(value)
  rescue
    ArgumentError -> nil
  end

  defp safe_to_existing_atom(_value), do: nil

  defp extract_value(%{"value" => value}), do: value

  defp extract_value(params) when is_map(params) do
    target_path = Map.get(params, "_target", [])

    case List.wrap(target_path) do
      [field_name | _rest] ->
        Map.get(params, field_name)

      _ ->
        field_name = Map.get(params, "name")
        if is_binary(field_name), do: Map.get(params, field_name), else: nil
    end
  end

  defp refresh_bindings(socket) do
    case UpdateIntegration.refresh_bindings(socket) do
      {:noreply, refreshed_socket} -> {:noreply, refreshed_socket}
      other -> other
    end
  end

  defp extract_action_event_data(%{"data" => data}) when is_map(data), do: data

  defp extract_action_event_data(params) when is_map(params) do
    params
    |> Map.drop(["action_id", "binding_id", "target", "value", "_target", "element_id", "signal"])
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp extract_binding_values(socket) do
    socket.assigns
    |> Map.get(:ash_ui_bindings, %{})
    |> Enum.reduce(%{}, fn {_binding_id, binding}, acc ->
      target = Map.get(binding, :target) || Map.get(binding, "target")
      value = Map.get(binding, :value) || Map.get(binding, "value")

      if is_nil(target) do
        acc
      else
        Map.put(acc, target, value)
      end
    end)
  end

  defp binding_target(binding) do
    Map.get(binding, :target) || Map.get(binding, "target")
  end

  defp binding_metadata(binding) do
    Map.get(binding, :metadata) || Map.get(binding, "metadata") || %{}
  end

  defp screen_bindings(socket) do
    Map.get(socket.assigns, :ash_ui_screen_bindings) ||
      BindingRuntime.partition(Map.get(socket.assigns, :ash_ui_bindings, %{})).screen
  end

  defp element_bindings(socket) do
    Map.get(socket.assigns, :ash_ui_element_bindings) ||
      BindingRuntime.partition(Map.get(socket.assigns, :ash_ui_bindings, %{})).elements
  end

  defp action_bindings(socket) do
    Map.get(socket.assigns, :ash_ui_action_bindings) ||
      BindingRuntime.partition(Map.get(socket.assigns, :ash_ui_bindings, %{})).actions
  end

  defp owner_element_matches?(_binding, nil), do: true

  defp owner_element_matches?(binding, element_id) do
    BindingRuntime.owner_element_id(binding) == element_id
  end

  defp signal_matches?(_binding, nil), do: true

  defp signal_matches?(binding, signal) do
    case BindingRuntime.owner_signal(binding) do
      nil -> true
      owner_signal -> owner_signal == to_string(signal)
    end
  end

  @doc """
  Wires all event handlers for a screen's bindings.

  Call this during screen mount to set up all event handlers.

  ## Examples

      def mount(params, session, socket) do
        {:ok, socket} = AshUI.LiveView.Integration.mount_ui_screen(socket, :dashboard, params)
        {:ok, socket} = AshUI.LiveView.EventHandler.wire_handlers(socket)
        {:ok, socket}
      end
  """
  @spec wire_handlers(Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def wire_handlers(socket) do
    bindings = socket.assigns[:ash_ui_bindings] || %{}

    # Create handler map for all bindings
    handlers = ActionBinding.wire_handlers(Map.values(bindings), socket)

    socket = Phoenix.Component.assign(socket, :ash_ui_handlers, handlers)
    {:ok, socket}
  end
end
