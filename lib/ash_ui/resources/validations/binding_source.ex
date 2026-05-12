defmodule AshUI.Resources.Validations.BindingSource do
  @moduledoc """
  Validates persisted binding source maps against the runtime-supported shapes.
  """

  use Ash.Resource.Validation

  alias Ash.Error.Changes.InvalidAttribute
  alias Ash.Subject

  @doc false
  @impl true
  def supports(_opts), do: [Ash.Changeset, Ash.ActionInput]

  @doc false
  @impl true
  def validate(subject, _opts, _context) do
    source = Subject.get_attribute(subject, :source)
    binding_type = Subject.get_attribute(subject, :binding_type)

    case validate_source(source, binding_type) do
      :ok ->
        :ok

      {:error, message} ->
        invalid_source(source, message)
    end
  end

  @doc """
  Validates a binding source map and returns a plain error message on failure.
  """
  @spec validate_source(term(), atom() | nil) :: :ok | {:error, String.t()}
  def validate_source(source, binding_type) do
    cond do
      row_scope_source?(source) ->
        validate_row_scope_source(source, binding_type)

      true ->
        with :ok <- validate_source_map(source),
             :ok <- validate_required_resource(source),
             :ok <- validate_shape(source, binding_type),
             :ok <- validate_optional_identifier(source, "field"),
             :ok <- validate_optional_identifier(source, "relationship"),
             :ok <- validate_optional_identifier(source, "action") do
          :ok
        else
          {:error, _message} = error -> error
        end
    end
  end

  # `%{scope: :row, field: "..."}` sources are used inside repeat templates.
  # They do not reference a resource — they reference whichever row the
  # repeat-expansion is currently iterating over. The validator therefore
  # short-circuits the resource requirement when the scope is `:row`.
  defp row_scope_source?(source) when is_map(source) do
    scope = Map.get(source, :scope) || Map.get(source, "scope")
    scope in [:row, "row"]
  end

  defp row_scope_source?(_source), do: false

  defp validate_row_scope_source(source, :value) do
    field = source_value(source, "field")

    if valid_identifier?(field) do
      :ok
    else
      {:error, "row-scoped bindings must include a non-empty field"}
    end
  end

  defp validate_row_scope_source(_source, :list) do
    {:error, "row-scoped bindings are only valid for :value bindings"}
  end

  defp validate_row_scope_source(_source, :action) do
    {:error, "row-scoped bindings are only valid for :value bindings"}
  end

  defp validate_row_scope_source(source, nil), do: validate_row_scope_source(source, :value)
  defp validate_row_scope_source(_source, _type), do: :ok

  defp validate_source_map(source) when is_map(source), do: :ok

  defp validate_source_map(_source) do
    {:error, "source must be a map"}
  end

  defp validate_required_resource(source) do
    if valid_identifier?(source_value(source, "resource")) do
      :ok
    else
      {:error, "source must include a non-empty resource reference"}
    end
  end

  defp validate_shape(_source, nil), do: :ok

  defp validate_shape(source, :value) do
    if valid_identifier?(source_value(source, "field")) or
         valid_identifier?(source_value(source, "relationship")) do
      :ok
    else
      {:error, "value bindings must include a field or relationship"}
    end
  end

  defp validate_shape(_source, :list), do: :ok

  defp validate_shape(source, :action) do
    if valid_identifier?(source_value(source, "action")) do
      :ok
    else
      {:error, "action bindings must include an action"}
    end
  end

  defp validate_shape(_source, _binding_type), do: :ok

  defp validate_optional_identifier(source, key) do
    value = source_value(source, key)

    cond do
      not source_has_key?(source, key) -> :ok
      valid_identifier?(value) -> :ok
      true -> {:error, "`#{key}` must be a non-empty string or atom"}
    end
  end

  defp source_value(source, key) do
    Map.get(source, key) || Map.get(source, String.to_atom(key))
  end

  defp source_has_key?(source, key) do
    Map.has_key?(source, key) || Map.has_key?(source, String.to_atom(key))
  end

  defp valid_identifier?(value) when is_binary(value), do: String.trim(value) != ""
  defp valid_identifier?(value) when is_atom(value), do: value not in [nil, false]
  defp valid_identifier?(_value), do: false

  defp invalid_source(source, message) do
    {:error, InvalidAttribute.exception(field: :source, value: source, message: message)}
  end
end
