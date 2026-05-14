defmodule LiveUi.Runtime.Error do
  @moduledoc """
  Deterministic runtime error contract for `live_ui`.
  """

  @enforce_keys [:reason, :message]
  defexception [:reason, :message, :details]

  @type t :: %__MODULE__{
          reason: atom(),
          message: String.t(),
          details: map() | nil
        }

  @spec invalid_screen_module(module()) :: t()
  def invalid_screen_module(screen) do
    %__MODULE__{
      reason: :invalid_screen_module,
      message: "screen module does not satisfy the LiveUi.Screen contract",
      details: %{screen: inspect(screen)}
    }
  end

  @spec invalid_mount_defaults(module()) :: t()
  def invalid_mount_defaults(screen) do
    %__MODULE__{
      reason: :invalid_mount_defaults,
      message: "screen mount defaults must be a map",
      details: %{screen: inspect(screen)}
    }
  end

  @spec invalid_event_route(module(), String.t()) :: t()
  def invalid_event_route(screen, event) do
    %__MODULE__{
      reason: :invalid_event_route,
      message: "event is not registered for the screen",
      details: %{screen: inspect(screen), event: event}
    }
  end

  @spec invalid_event_result(module(), atom(), term()) :: t()
  def invalid_event_result(screen, route, result) do
    %__MODULE__{
      reason: :invalid_event_result,
      message: "screen event handlers must return {:ok, map()} or {:error, reason}",
      details: %{screen: inspect(screen), route: route, result: inspect(result)}
    }
  end

  @spec unresolved_navigation_target(atom() | String.t() | nil, term(), term()) :: t()
  def unresolved_navigation_target(action, screen_id, reason) do
    %__MODULE__{
      reason: :unresolved_navigation_target,
      message: "canonical navigation transitions require a resolvable symbolic screen target",
      details: %{action: action, screen_id: screen_id, reason: inspect(reason)}
    }
  end

  @spec unsupported_navigation_context(atom() | String.t() | nil, map()) :: t()
  def unsupported_navigation_context(action, details \\ %{}) do
    %__MODULE__{
      reason: :unsupported_navigation_context,
      message:
        "canonical navigation transition cannot be applied in the current live_ui runtime context",
      details: Map.put(Map.new(details), :action, action)
    }
  end

  @spec host_route_navigation_syntax([atom() | String.t()]) :: t()
  def host_route_navigation_syntax(keys) do
    %__MODULE__{
      reason: :host_route_navigation_syntax,
      message: "canonical navigation targets must not contain host-router syntax",
      details: %{keys: keys}
    }
  end

  @spec widget_event_failed(term()) :: t()
  def widget_event_failed(reason) do
    %__MODULE__{
      reason: :widget_event_failed,
      message: "widget event handler failed",
      details: %{reason: inspect(reason)}
    }
  end

  @spec invalid_widget_event_payload() :: t()
  def invalid_widget_event_payload do
    %__MODULE__{
      reason: :invalid_widget_event_payload,
      message: "widget event payload must contain widget_component, widget_key, and widget_event",
      details: nil
    }
  end
end
