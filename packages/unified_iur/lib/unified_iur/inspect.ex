defmodule UnifiedIUR.Inspect do
  @moduledoc """
  Maintainer-facing inspection helpers for canonical `UnifiedIUR` values.
  """

  alias UnifiedIUR.{
    Element,
    Extension,
    Fixtures,
    Interaction,
    Interoperability,
    Normalize,
    Reference,
    Validate
  }

  @type inspection_report :: %{
          fixture_id: String.t() | nil,
          identity: map() | nil,
          element_summary: map() | nil,
          tree_summary: map() | nil,
          classification: map() | nil,
          render_tree: String.t() | nil,
          attachments: [map()],
          styles: [map()],
          themes: [map()],
          interactions: [map()],
          diagnostics: map()
        }

  @spec fixture(String.t()) :: {:ok, inspection_report()} | :error
  def fixture(id) when is_binary(id) do
    case Fixtures.fixture(id) do
      {:ok, fixture} ->
        {:ok, Map.put(element(fixture.element), :fixture_id, fixture.id)}

      :error ->
        :error
    end
  end

  @spec navigation_fixture(String.t()) :: {:ok, map()} | :error
  def navigation_fixture(id) when is_binary(id) do
    case Fixtures.navigation_fixture(id) do
      {:ok, fixture} ->
        {:ok,
         fixture.interaction
         |> interaction()
         |> Map.put(:fixture_id, fixture.id)
         |> Map.put(:description, fixture.description)
         |> Map.put(:semantics, fixture.semantics)
         |> Map.put(:snapshot_path, fixture.snapshot_path)}

      :error ->
        :error
    end
  end

  @spec element(Element.t() | map() | keyword()) :: inspection_report()
  def element(input) do
    element = Normalize.element!(input)

    %{
      fixture_id: nil,
      identity: Interoperability.identity(element),
      element_summary: Reference.summarize_element(element),
      tree_summary: Reference.summarize_tree(element),
      classification: Interoperability.classify(element),
      render_tree: render_tree(element),
      attachments: Interoperability.attachments(element),
      styles: styles(element),
      themes: themes(element),
      interactions: interactions(element),
      diagnostics: Validate.diagnostics(element)
    }
  end

  @spec interaction(Interaction.t() | map() | keyword()) :: map()
  def interaction(input) do
    interaction = Interaction.new(input)

    %{
      family: interaction.family,
      intent: interaction.intent,
      source: interaction.source,
      target: interaction.target,
      navigation: Interaction.navigation_descriptor(interaction),
      payload: interaction.payload,
      metadata: interaction.metadata
    }
  end

  @spec render_tree(Element.t() | map() | keyword()) :: String.t()
  def render_tree(input) do
    input
    |> Normalize.element!()
    |> render_lines(0)
    |> Enum.join("\n")
  end

  @spec styles(Element.t() | map() | keyword()) :: [map()]
  def styles(input) do
    input
    |> Interoperability.walk()
    |> Enum.flat_map(fn element ->
      style = Map.get(element.attributes, :style)
      style_refs = Map.get(element.attributes, :style_refs, [])

      if is_nil(style) and style_refs == [] do
        []
      else
        [
          %{
            id: element.id,
            kind: element.kind,
            style: style,
            style_refs: style_refs
          }
        ]
      end
    end)
  end

  @spec themes(Element.t() | map() | keyword()) :: [map()]
  def themes(input) do
    input
    |> Interoperability.walk()
    |> Enum.flat_map(fn element ->
      case Map.fetch(element.attributes, :theme) do
        {:ok, theme} ->
          [
            %{
              id: element.id,
              kind: element.kind,
              theme: theme,
              theme_refs: Map.get(element.attributes, :theme_refs, [])
            }
          ]

        :error ->
          []
      end
    end)
  end

  @spec interactions(Element.t() | map() | keyword()) :: [map()]
  def interactions(input) do
    input
    |> Interoperability.walk()
    |> Enum.flat_map(fn element ->
      element.attributes
      |> Map.get(:interactions, [])
      |> Enum.map(fn interaction ->
        interaction
        |> interaction()
        |> Map.merge(%{
          id: element.id,
          kind: element.kind,
          interaction: Interaction.new(interaction)
        })
      end)
    end)
  end

  @spec extension_metadata() :: map()
  def extension_metadata do
    %{
      extension_points: Extension.extension_points(),
      compatibility_rules: Extension.compatibility_rules(),
      iur_catalog: Extension.iur_catalog(),
      unified_ui_family_map: Extension.unified_ui_family_map()
    }
  end

  defp render_lines(%Element{} = element, depth) do
    current_line = "#{indent(depth)}- #{element.id} [#{element.type}:#{element.kind}]"

    child_lines =
      Enum.flat_map(element.children, fn child ->
        slot_line = "#{indent(depth + 1)}@#{child.slot}"

        case child.element do
          nil ->
            [slot_line <> " nil"]

          child_element ->
            [slot_line | render_lines(child_element, depth + 2)]
        end
      end)

    [current_line | child_lines]
  end

  defp indent(depth), do: String.duplicate("  ", depth)
end
