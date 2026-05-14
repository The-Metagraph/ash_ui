defmodule UnifiedUi.Signals do
  @moduledoc """
  Package-facing helpers for canonical signal and binding authoring support.
  """

  alias Spark.Dsl.Extension
  alias UnifiedUi.{Binding, Signal}

  @spec families() :: [Signal.family()]
  def families do
    Signal.families()
  end

  @spec navigation_actions() :: [Signal.navigation_transition_action()]
  def navigation_actions do
    Signal.navigation_actions()
  end

  @spec navigation_action_contracts() :: %{
          Signal.navigation_transition_action() => Signal.navigation_action_contract()
        }
  def navigation_action_contracts do
    Signal.navigation_action_contracts()
  end

  @spec navigation_transition_fields() :: [atom()]
  def navigation_transition_fields do
    Signal.navigation_transition_fields()
  end

  @spec local_navigation_fields() :: [atom()]
  def local_navigation_fields do
    Signal.local_navigation_fields()
  end

  @spec navigation_modal_stack_semantics() :: %{
          Signal.navigation_transition_action() => Signal.modal_stack_semantics()
        }
  def navigation_modal_stack_semantics do
    Signal.navigation_modal_stack_semantics()
  end

  @spec navigation_target_kind(Signal.t() | map() | keyword()) :: Signal.navigation_target_kind()
  def navigation_target_kind(signal) do
    Signal.navigation_target_kind(signal)
  end

  @spec navigation_descriptor(Signal.t() | map() | keyword()) :: Signal.navigation_descriptor()
  def navigation_descriptor(signal) do
    Signal.navigation_descriptor(signal)
  end

  @spec bindings(module()) :: [Binding.t()]
  def bindings(module) when is_atom(module) do
    module
    |> Extension.get_entities([:signals])
    |> Enum.filter(&match?(%Binding{}, &1))
  end

  @spec interactions(module()) :: [Signal.t()]
  def interactions(module) when is_atom(module) do
    module
    |> Extension.get_entities([:signals])
    |> Enum.filter(&match?(%Signal{}, &1))
  end

  @spec navigation_descriptors(module()) :: [Signal.navigation_descriptor()]
  def navigation_descriptors(module) when is_atom(module) do
    module
    |> interactions()
    |> Enum.filter(&(&1.family == :navigation))
    |> Enum.map(&Signal.navigation_descriptor/1)
    |> Enum.sort_by(&Map.get(&1, :id))
  end

  @spec module_summary(module()) :: map()
  def module_summary(module) when is_atom(module) do
    %{
      namespace: Extension.get_opt(module, [:signals], :namespace, nil),
      default_target: Extension.get_opt(module, [:signals], :default_target, nil),
      mode: Extension.get_opt(module, [:signals], :mode, :canonical),
      families: families(),
      bindings: Enum.map(bindings(module), &Binding.summary/1),
      interactions: Enum.map(interactions(module), &Signal.summary/1),
      navigation_descriptors: navigation_descriptors(module)
    }
  end
end
