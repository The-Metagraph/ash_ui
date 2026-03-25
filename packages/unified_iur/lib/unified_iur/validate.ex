defmodule UnifiedIUR.Validate do
  @moduledoc """
  Canonical validation helpers for normalized `UnifiedIUR` values.
  """

  alias UnifiedIUR.{Binding, Element, Interaction, Metadata, Style}
  alias UnifiedIUR.Element.Child
  alias UnifiedIUR.Validate.Error

  @runtime_local_prefixes [
    "DesktopUi",
    "LiveUi",
    "ElmUi",
    "UnifiedUi",
    "Phoenix.LiveView",
    "Jido.Signal"
  ]

  @guidance_by_code %{
    invalid_element: %{
      construct_family: :core_model,
      guidance:
        "Validate values through UnifiedIUR.Normalize and ensure the root is a UnifiedIUR.Element."
    },
    missing_type: %{
      construct_family: :core_model,
      guidance:
        "Create elements through package constructors so canonical type values stay explicit."
    },
    missing_kind: %{
      construct_family: :core_model,
      guidance:
        "Use a known canonical kind from UnifiedIUR.Core, Widgets, Layout, Layer, Forms, or Canvas."
    },
    invalid_metadata: %{
      construct_family: :core_model,
      guidance:
        "Attach metadata through UnifiedIUR.Metadata so description, tags, and annotations stay portable."
    },
    invalid_children: %{
      construct_family: :display_systems,
      guidance: "Represent children as UnifiedIUR.Element.Child values with stable slot names."
    },
    invalid_child: %{
      construct_family: :display_systems,
      guidance:
        "Wrap nested elements with UnifiedIUR.Element.Child.new/2 or package constructors that do so for you."
    },
    invalid_style_attachment: %{
      construct_family: :theming,
      guidance: "Attach styles as UnifiedIUR.Style structs and keep style references portable."
    },
    invalid_theme_attachment: %{
      construct_family: :theming,
      guidance:
        "Attach themes as canonical maps or token references rather than runtime-local theme structs."
    },
    invalid_interaction_attachment: %{
      construct_family: :interactions,
      guidance: "Populate :interactions with UnifiedIUR.Interaction structs only."
    },
    invalid_interactions_attachment: %{
      construct_family: :interactions,
      guidance: "Keep the :interactions attachment as a list of UnifiedIUR.Interaction structs."
    },
    invalid_binding_attachment: %{
      construct_family: :interactions,
      guidance: "Populate :bindings with UnifiedIUR.Binding structs only."
    },
    invalid_bindings_attachment: %{
      construct_family: :interactions,
      guidance: "Keep the :bindings attachment as a list of UnifiedIUR.Binding structs."
    },
    invalid_interaction_scope: %{
      construct_family: :interactions,
      guidance:
        "Represent interaction_scope as a canonical map describing portable routing context."
    },
    runtime_local_escape_hatch: %{
      construct_family: :interoperability,
      guidance:
        "Keep runtime-native structs out of canonical IUR and translate them at runtime-library boundaries."
    }
  }

  @spec element(Element.t()) :: :ok | {:error, [Error.t()]}
  def element(%Element{} = element) do
    errors =
      []
      |> Kernel.++(validate_element_shape(element))
      |> Kernel.++(validate_metadata(element.metadata))
      |> Kernel.++(validate_attachments(element.attributes))
      |> Kernel.++(validate_runtime_local_values(element.attributes, [:attributes]))
      |> Kernel.++(validate_children(element.children))

    if errors == [], do: :ok, else: {:error, errors}
  end

  def element(other) do
    {:error,
     [
       Error.new(
         :invalid_element,
         "validation expects a canonical UnifiedIUR.Element struct",
         details: %{value: inspect(other)}
       )
     ]}
  end

  defp validate_element_shape(%Element{type: type, kind: kind}) do
    []
    |> maybe_add(
      is_nil(type),
      Error.new(:missing_type, "element type is required", path: [:type])
    )
    |> maybe_add(
      is_nil(kind),
      Error.new(:missing_kind, "element kind is required", path: [:kind])
    )
  end

  defp validate_metadata(%Metadata{}), do: []

  defp validate_metadata(other) do
    [
      Error.new(
        :invalid_metadata,
        "element metadata must be a UnifiedIUR.Metadata struct",
        path: [:metadata],
        details: %{value: inspect(other)}
      )
    ]
  end

  @spec diagnostics(Element.t() | map() | keyword()) :: map()
  def diagnostics(input) do
    case UnifiedIUR.Normalize.element(input) do
      {:ok, element} ->
        case element(element) do
          :ok ->
            %{
              valid?: true,
              identity: %{id: element.id, type: element.type, kind: element.kind},
              errors: [],
              construct_families: []
            }

          {:error, errors} ->
            %{
              valid?: false,
              identity: %{id: element.id, type: element.type, kind: element.kind},
              errors: Enum.map(errors, &diagnostic_entry/1),
              construct_families:
                errors
                |> Enum.map(&guidance_for_error/1)
                |> Enum.map(& &1.construct_family)
                |> Enum.uniq()
                |> Enum.sort()
            }
        end

      {:error, errors} ->
        %{
          valid?: false,
          identity: nil,
          errors: Enum.map(errors, &diagnostic_entry/1),
          construct_families:
            errors
            |> Enum.map(&guidance_for_error/1)
            |> Enum.map(& &1.construct_family)
            |> Enum.uniq()
            |> Enum.sort()
        }
    end
  end

  @spec guidance_for_error(Error.t() | atom()) :: %{
          construct_family: atom(),
          guidance: String.t()
        }
  def guidance_for_error(%Error{code: code}), do: guidance_for_error(code)

  def guidance_for_error(code) when is_atom(code) do
    Map.get(@guidance_by_code, code, %{
      construct_family: :unknown,
      guidance:
        "Review the canonical construct family and normalize the value before export or validation."
    })
  end

  defp validate_children(children) when is_list(children) do
    Enum.flat_map(Enum.with_index(children), fn {child, index} ->
      validate_child(child, [:children, index])
    end)
  end

  defp validate_children(other) do
    [
      Error.new(
        :invalid_children,
        "element children must be a list",
        path: [:children],
        details: %{value: inspect(other)}
      )
    ]
  end

  defp validate_child(%Child{slot: slot, element: nil}, _path)
       when is_atom(slot) or is_binary(slot),
       do: []

  defp validate_child(%Child{slot: slot, element: %Element{} = element}, path)
       when is_atom(slot) or is_binary(slot) do
    case element(element) do
      :ok -> []
      {:error, errors} -> Enum.map(errors, &prepend_path(&1, path))
    end
  end

  defp validate_child(%Child{}, path) do
    [
      Error.new(:invalid_child, "child slot must be an atom or string", path: path)
    ]
  end

  defp validate_child(other, path) do
    [
      Error.new(
        :invalid_child,
        "children must be UnifiedIUR.Element.Child structs",
        path: path,
        details: %{value: inspect(other)}
      )
    ]
  end

  defp validate_attachments(attributes) when is_map(attributes) do
    []
    |> validate_style(attributes)
    |> validate_theme(attributes)
    |> validate_interactions(attributes)
    |> validate_bindings(attributes)
    |> validate_interaction_scope(attributes)
  end

  defp validate_attachments(_other), do: []

  defp validate_style(errors, %{style: %Style{}}), do: errors

  defp validate_style(errors, %{style: style}) do
    errors ++
      [
        Error.new(
          :invalid_style_attachment,
          "style attachment must be a UnifiedIUR.Style struct",
          path: [:attributes, :style],
          details: %{value: inspect(style)}
        )
      ]
  end

  defp validate_style(errors, _attributes), do: errors

  defp validate_theme(errors, %{theme: theme}) when is_map(theme), do: errors

  defp validate_theme(errors, %{theme: theme}) do
    errors ++
      [
        Error.new(
          :invalid_theme_attachment,
          "theme attachment must be a map",
          path: [:attributes, :theme],
          details: %{value: inspect(theme)}
        )
      ]
  end

  defp validate_theme(errors, _attributes), do: errors

  defp validate_interactions(errors, %{interactions: interactions}) when is_list(interactions) do
    interaction_errors =
      interactions
      |> Enum.with_index()
      |> Enum.flat_map(fn
        {%Interaction{}, _index} ->
          []

        {interaction, index} ->
          [
            Error.new(
              :invalid_interaction_attachment,
              "interactions attachment must contain UnifiedIUR.Interaction structs",
              path: [:attributes, :interactions, index],
              details: %{value: inspect(interaction)}
            )
          ]
      end)

    errors ++ interaction_errors
  end

  defp validate_interactions(errors, %{interactions: value}) do
    errors ++
      [
        Error.new(
          :invalid_interactions_attachment,
          "interactions attachment must be a list",
          path: [:attributes, :interactions],
          details: %{value: inspect(value)}
        )
      ]
  end

  defp validate_interactions(errors, _attributes), do: errors

  defp validate_bindings(errors, %{bindings: bindings}) when is_list(bindings) do
    binding_errors =
      bindings
      |> Enum.with_index()
      |> Enum.flat_map(fn
        {%Binding{}, _index} ->
          []

        {binding, index} ->
          [
            Error.new(
              :invalid_binding_attachment,
              "bindings attachment must contain UnifiedIUR.Binding structs",
              path: [:attributes, :bindings, index],
              details: %{value: inspect(binding)}
            )
          ]
      end)

    errors ++ binding_errors
  end

  defp validate_bindings(errors, %{bindings: value}) do
    errors ++
      [
        Error.new(
          :invalid_bindings_attachment,
          "bindings attachment must be a list",
          path: [:attributes, :bindings],
          details: %{value: inspect(value)}
        )
      ]
  end

  defp validate_bindings(errors, _attributes), do: errors

  defp validate_interaction_scope(errors, %{interaction_scope: scope}) when is_map(scope),
    do: errors

  defp validate_interaction_scope(errors, %{interaction_scope: scope}) do
    errors ++
      [
        Error.new(
          :invalid_interaction_scope,
          "interaction_scope attachment must be a map",
          path: [:attributes, :interaction_scope],
          details: %{value: inspect(scope)}
        )
      ]
  end

  defp validate_interaction_scope(errors, _attributes), do: errors

  defp validate_runtime_local_values(value, path) when is_list(value) do
    value
    |> Enum.with_index()
    |> Enum.flat_map(fn {item, index} -> validate_runtime_local_values(item, path ++ [index]) end)
  end

  defp validate_runtime_local_values(%Element{} = element, path) do
    case element(element) do
      :ok -> []
      {:error, errors} -> Enum.map(errors, &prepend_path(&1, path))
    end
  end

  defp validate_runtime_local_values(%Child{} = child, path) do
    validate_child(child, path)
  end

  defp validate_runtime_local_values(%_{} = struct, path) do
    module = struct.__struct__

    cond do
      runtime_local_struct?(module) ->
        [
          Error.new(
            :runtime_local_escape_hatch,
            "runtime-local structs are not allowed in canonical IUR values",
            path: path,
            details: %{module: inspect(module)}
          )
        ]

      true ->
        struct
        |> Map.from_struct()
        |> validate_runtime_local_values(path)
    end
  end

  defp validate_runtime_local_values(map, path) when is_map(map) do
    Enum.flat_map(map, fn {key, value} -> validate_runtime_local_values(value, path ++ [key]) end)
  end

  defp validate_runtime_local_values(_value, _path), do: []

  defp runtime_local_struct?(module) do
    parts = Module.split(module)
    name = Enum.join(parts, ".")

    Enum.any?(@runtime_local_prefixes, fn prefix ->
      String.starts_with?(name, prefix) or prefix_in_parts?(parts, String.split(prefix, "."))
    end)
  end

  defp prefix_in_parts?(parts, prefix_parts) do
    parts
    |> Enum.chunk_every(length(prefix_parts), 1, :discard)
    |> Enum.any?(&(&1 == prefix_parts))
  end

  defp maybe_add(errors, true, error), do: errors ++ [error]
  defp maybe_add(errors, false, _error), do: errors

  defp prepend_path(%Error{} = error, prefix) do
    %{error | path: prefix ++ error.path}
  end

  defp diagnostic_entry(%Error{} = error) do
    guidance = guidance_for_error(error)

    %{
      code: error.code,
      message: Error.format(error),
      path: error.path,
      details: error.details,
      construct_family: guidance.construct_family,
      guidance: guidance.guidance
    }
  end
end
