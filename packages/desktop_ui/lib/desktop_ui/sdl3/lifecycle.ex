defmodule DesktopUi.Sdl3.Lifecycle do
  @moduledoc """
  Callback-oriented SDL3 application lifecycle state for `desktop_ui`.
  """

  @callback_names [:app_init, :app_event, :app_iterate, :app_quit]

  @enforce_keys [:state, :callbacks, :transitions]
  defstruct [:state, :callbacks, :transitions, :boot_request, :last_error]

  @type callback_name :: :app_init | :app_event | :app_iterate | :app_quit

  @type t :: %__MODULE__{
          state: atom(),
          callbacks: %{optional(callback_name()) => atom()},
          transitions: [map()],
          boot_request: map() | nil,
          last_error: map() | nil
        }

  @spec callback_names() :: [callback_name()]
  def callback_names, do: @callback_names

  @spec contract() :: map()
  def contract do
    %{
      model: :callback_oriented,
      callbacks: callback_names(),
      callback_payload_shape: :map,
      ordering: [:app_init, :app_event, :app_iterate, :app_quit],
      foundation: :sdl3
    }
  end

  @spec scaffold() :: t()
  def scaffold do
    %__MODULE__{
      state: :created,
      callbacks: Map.new(callback_names(), &{&1, :pending}),
      transitions: [%{to: :created, reason: :scaffolded}],
      boot_request: nil,
      last_error: nil
    }
  end

  @spec begin_boot(t(), map()) :: t()
  def begin_boot(%__MODULE__{} = lifecycle, boot_request) when is_map(boot_request) do
    lifecycle
    |> Map.put(:state, :booting)
    |> Map.put(:boot_request, boot_request)
    |> add_transition(:booting, :boot_request_ready)
  end

  @spec record_callback(t(), callback_name(), atom()) :: t()
  def record_callback(%__MODULE__{} = lifecycle, callback, status \\ :ready)
      when callback in @callback_names and is_atom(status) do
    lifecycle
    |> put_in([Access.key(:callbacks), callback], status)
    |> add_transition(lifecycle.state, {:callback_recorded, callback, status})
  end

  @spec ready(t()) :: t()
  def ready(%__MODULE__{} = lifecycle) do
    lifecycle
    |> Map.put(:state, :ready)
    |> add_transition(:ready, :init_complete)
  end

  @spec begin_shutdown(t()) :: t()
  def begin_shutdown(%__MODULE__{} = lifecycle) do
    lifecycle
    |> Map.put(:state, :shutting_down)
    |> add_transition(:shutting_down, :shutdown_requested)
  end

  @spec fail(t(), atom(), map()) :: t()
  def fail(%__MODULE__{} = lifecycle, reason, details \\ %{})
      when is_atom(reason) and is_map(details) do
    lifecycle
    |> Map.put(:state, :error)
    |> Map.put(:last_error, %{reason: reason, details: details})
    |> add_transition(:error, {:failed, reason})
  end

  @spec diagnostics(t()) :: map()
  def diagnostics(%__MODULE__{} = lifecycle) do
    %{
      state: lifecycle.state,
      callbacks: lifecycle.callbacks,
      transition_count: length(lifecycle.transitions),
      transitions: lifecycle.transitions,
      last_error: lifecycle.last_error,
      contract: contract()
    }
  end

  defp add_transition(%__MODULE__{} = lifecycle, to, reason) do
    transition = %{to: to, reason: reason}
    Map.update!(lifecycle, :transitions, &(&1 ++ [transition]))
  end
end
