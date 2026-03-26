defmodule UnifiedIUR.Token do
  @moduledoc """
  Canonical design-token values and references for `UnifiedIUR` style and theme
  reuse.
  """

  @type path_segment :: atom() | String.t()
  @type path :: [path_segment()]

  @type ref_t :: %{
          kind: :token_ref,
          path: path()
        }

  @type definition_t :: %{
          kind: :token,
          path: path(),
          value: term()
        }

  @spec ref(path() | path_segment()) :: ref_t()
  def ref(path) when is_atom(path) or is_binary(path), do: ref([path])
  def ref(path) when is_list(path), do: %{kind: :token_ref, path: path}

  @spec define(path() | path_segment(), term()) :: definition_t()
  def define(path, value) when is_atom(path) or is_binary(path), do: define([path], value)
  def define(path, value) when is_list(path), do: %{kind: :token, path: path, value: value}

  @spec new(term()) :: ref_t() | definition_t() | nil
  def new(nil), do: nil
  def new(%{kind: :token_ref, path: path}) when is_list(path), do: ref(path)
  def new(%{"kind" => :token_ref, "path" => path}) when is_list(path), do: ref(path)
  def new(%{kind: :token, path: path, value: value}) when is_list(path), do: define(path, value)

  def new(%{"kind" => :token, "path" => path, "value" => value}) when is_list(path),
    do: define(path, value)

  def new(path) when is_atom(path) or is_binary(path) or is_list(path), do: ref(path)

  @spec reference?(term()) :: boolean()
  def reference?(%{kind: :token_ref, path: path}) when is_list(path), do: true
  def reference?(_other), do: false
end
