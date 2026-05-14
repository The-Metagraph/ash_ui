defmodule DesktopUi.Transport.Error do
  @moduledoc """
  Deterministic transport diagnostics for `desktop_ui`.
  """

  @enforce_keys [:reason, :message]
  defexception [:reason, :message, :details]

  @type t :: %__MODULE__{
          reason: atom(),
          message: String.t(),
          details: map() | nil
        }

  @spec invalid_family(term()) :: t()
  def invalid_family(family) do
    %__MODULE__{
      reason: :invalid_family,
      message: "desktop_ui transport requires a supported canonical interaction family",
      details: %{family: inspect(family)}
    }
  end

  @spec invalid_native_event(term()) :: t()
  def invalid_native_event(value) do
    %__MODULE__{
      reason: :invalid_native_event,
      message: "native desktop events must normalize into the shared desktop interaction model",
      details: %{value: inspect(value)}
    }
  end

  @spec ambiguous_native_event(term()) :: t()
  def ambiguous_native_event(value) do
    %__MODULE__{
      reason: :ambiguous_native_event,
      message: "native desktop input must resolve to one shared input family",
      details: %{value: inspect(value)}
    }
  end

  @spec invalid_payload_mapping(term(), atom()) :: t()
  def invalid_payload_mapping(value, surface) do
    %__MODULE__{
      reason: :invalid_payload_mapping,
      message: "desktop_ui boundary payloads must be plain maps",
      details: %{value: inspect(value), surface: surface}
    }
  end

  @spec invalid_boundary_signal(term()) :: t()
  def invalid_boundary_signal(value) do
    %__MODULE__{
      reason: :invalid_boundary_signal,
      message: "boundary signals must contain canonical desktop_ui transport extensions",
      details: %{value: inspect(value)}
    }
  end

  @spec missing_boundary_context([atom()]) :: t()
  def missing_boundary_context(fields) do
    %__MODULE__{
      reason: :missing_boundary_context,
      message: "desktop boundary translation requires stable screen and runtime context",
      details: %{fields: fields}
    }
  end

  @spec leaked_platform_detail([atom() | String.t()]) :: t()
  def leaked_platform_detail(keys) do
    %__MODULE__{
      reason: :leaked_platform_detail,
      message: "platform-local desktop payload details must not leak across the package boundary",
      details: %{keys: keys}
    }
  end

  @spec host_route_syntax([atom() | String.t()]) :: t()
  def host_route_syntax(keys) do
    %__MODULE__{
      reason: :host_route_syntax,
      message:
        "host-router and runtime-module syntax must not cross the desktop_ui navigation boundary",
      details: %{keys: keys}
    }
  end

  @spec unsupported_platform_target(term()) :: t()
  def unsupported_platform_target(target) do
    %__MODULE__{
      reason: :unsupported_platform_target,
      message: "desktop_ui transport supports only the declared desktop targets",
      details: %{platform_target: inspect(target)}
    }
  end
end
