defmodule ElmUi.Transport.Error do
  @moduledoc """
  Deterministic transport error contract for canonical boundary translation in
  `elm_ui`.
  """

  @enforce_keys [:reason, :message]
  defexception [:reason, :message, :details]

  @type t :: %__MODULE__{
          reason: atom(),
          message: String.t(),
          details: map() | nil
        }

  @spec renderer_local_event_name(String.t(), atom()) :: t()
  def renderer_local_event_name(event_name, surface) do
    %__MODULE__{
      reason: :renderer_local_event_name,
      message: "renderer-local event names must not enter the elm_ui transport contract",
      details: %{event_name: event_name, surface: surface}
    }
  end

  @spec renderer_local_payload([atom() | String.t()], atom()) :: t()
  def renderer_local_payload(keys, surface) do
    %__MODULE__{
      reason: :renderer_local_payload,
      message: "renderer-local payload keys must not cross the elm_ui transport boundary",
      details: %{keys: keys, surface: surface}
    }
  end

  @spec missing_boundary_context([atom()]) :: t()
  def missing_boundary_context(fields) do
    %__MODULE__{
      reason: :missing_boundary_context,
      message: "canonical boundary translation requires stable screen and runtime context",
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
      message: "boundary signals must contain canonical elm_ui extensions and event context",
      details: %{value: inspect(value)}
    }
  end

  @spec host_route_syntax([atom() | String.t()]) :: t()
  def host_route_syntax(keys) do
    %__MODULE__{
      reason: :host_route_syntax,
      message: "host-route syntax must not cross the canonical elm_ui navigation contract",
      details: %{keys: keys}
    }
  end

  @spec invalid_boundary_envelope(term()) :: t()
  def invalid_boundary_envelope(value) do
    %__MODULE__{
      reason: :invalid_boundary_envelope,
      message: "boundary envelopes must wrap a canonical elm_ui signal payload",
      details: %{value: inspect(value)}
    }
  end

  @spec package_local_transport_detail([atom() | String.t()]) :: t()
  def package_local_transport_detail(keys) do
    %__MODULE__{
      reason: :package_local_transport_detail,
      message: "package-local transport details must not be supplied as canonical input",
      details: %{keys: keys}
    }
  end

  @spec invalid_payload_mapping(term(), atom()) :: t()
  def invalid_payload_mapping(value, surface) do
    %__MODULE__{
      reason: :invalid_payload_mapping,
      message: "transport payloads must be mappable as plain maps",
      details: %{value: inspect(value), surface: surface}
    }
  end
end
