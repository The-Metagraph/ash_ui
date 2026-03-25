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

  @spec module_summary(module()) :: map()
  def module_summary(module) when is_atom(module) do
    %{
      namespace: Extension.get_opt(module, [:signals], :namespace, nil),
      default_target: Extension.get_opt(module, [:signals], :default_target, nil),
      mode: Extension.get_opt(module, [:signals], :mode, :canonical),
      families: families(),
      bindings: Enum.map(bindings(module), &Binding.summary/1),
      interactions: Enum.map(interactions(module), &Signal.summary/1)
    }
  end
end
