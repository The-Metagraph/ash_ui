defmodule LiveUi.Transport.Error do
  @moduledoc """
  Deterministic transport error contract for canonical boundary translation.
  """

  @enforce_keys [:reason, :message]
  defexception [:reason, :message, :details]

  @type t :: %__MODULE__{
          reason: atom(),
          message: String.t(),
          details: map() | nil
        }

  @spec renderer_local_event_name(String.t()) :: t()
  def renderer_local_event_name(event_name) do
    %__MODULE__{
      reason: :renderer_local_event_name,
      message: "renderer-local event names must not cross the canonical boundary",
      details: %{event_name: event_name}
    }
  end

  @spec renderer_local_payload([atom() | String.t()]) :: t()
  def renderer_local_payload(keys) do
    %__MODULE__{
      reason: :renderer_local_payload,
      message: "renderer-local payload keys must not cross the canonical boundary",
      details: %{keys: keys}
    }
  end

  @spec missing_boundary_context([atom()]) :: t()
  def missing_boundary_context(fields) do
    %__MODULE__{
      reason: :missing_boundary_context,
      message: "canonical boundary translation requires stable screen and element context",
      details: %{fields: fields}
    }
  end

  @spec invalid_family(term()) :: t()
  def invalid_family(family) do
    %__MODULE__{
      reason: :invalid_family,
      message: "canonical boundary translation requires a supported interaction family",
      details: %{family: inspect(family)}
    }
  end

  @spec invalid_boundary_signal(term()) :: t()
  def invalid_boundary_signal(value) do
    %__MODULE__{
      reason: :invalid_boundary_signal,
      message: "boundary signals must contain canonical live_ui extensions and event context",
      details: %{value: inspect(value)}
    }
  end

  @spec host_route_syntax([atom() | String.t()]) :: t()
  def host_route_syntax(keys) do
    %__MODULE__{
      reason: :host_route_syntax,
      message: "host-route syntax must not cross the canonical live_ui navigation contract",
      details: %{keys: keys}
    }
  end

  @spec invalid_channel_envelope(term()) :: t()
  def invalid_channel_envelope(value) do
    %__MODULE__{
      reason: :invalid_channel_envelope,
      message: "channel envelopes must wrap a canonical boundary signal payload",
      details: %{value: inspect(value)}
    }
  end

  @spec unsupported_hook(atom()) :: t()
  def unsupported_hook(hook) do
    %__MODULE__{
      reason: :unsupported_hook,
      message: "browser hook is not part of the bounded live_ui hook contract",
      details: %{hook: hook}
    }
  end
end
