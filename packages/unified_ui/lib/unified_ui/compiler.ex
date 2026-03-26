defmodule UnifiedUi.Compiler do
  @moduledoc """
  Public compiler entrypoints for lowering authored `UnifiedUi` modules into
  canonical `UnifiedIUR` output.
  """

  alias UnifiedUi.Compiler.{Inspection, Pipeline, Result}

  @type compile_result :: {:ok, Result.t()}

  @spec compile(module(), keyword() | map()) :: compile_result()
  def compile(module, opts \\ []) when is_atom(module) do
    {:ok, Pipeline.run(module, opts)}
  end

  @spec compile!(module(), keyword() | map()) :: Result.t()
  def compile!(module, opts \\ []) when is_atom(module) do
    Pipeline.run(module, opts)
  end

  @spec compile_fragment(module(), keyword() | map()) :: compile_result()
  def compile_fragment(module, opts \\ []) when is_atom(module) do
    result = compile!(module, opts)

    if result.composition.mode == :fragment do
      {:ok, result}
    else
      raise ArgumentError,
            "expected #{inspect(module)} to compile as a fragment, got #{inspect(result.composition.mode)}"
    end
  end

  @spec iur(module(), keyword() | map()) :: {:ok, UnifiedIUR.Element.t()}
  def iur(module, opts \\ []) when is_atom(module) do
    {:ok, compile!(module, opts).iur}
  end

  @spec iur!(module(), keyword() | map()) :: UnifiedIUR.Element.t()
  def iur!(module, opts \\ []) when is_atom(module) do
    compile!(module, opts).iur
  end

  @spec summary(module(), keyword() | map()) :: map()
  def summary(module, opts \\ []) when is_atom(module) do
    module
    |> compile!(opts)
    |> Result.summary()
  end

  @spec listing(module(), keyword() | map()) :: map()
  def listing(module, opts \\ []) when is_atom(module) do
    module
    |> compile!(opts)
    |> Result.listing()
  end

  @spec inspection(module(), keyword() | map()) :: map()
  def inspection(module, opts \\ []) when is_atom(module) do
    Inspection.report(module, opts)
  end

  @spec render_inspection(module(), keyword() | map()) :: String.t()
  def render_inspection(module, opts \\ []) when is_atom(module) do
    Inspection.render(module, opts)
  end
end
