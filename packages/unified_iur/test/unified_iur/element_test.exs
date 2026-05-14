defmodule UnifiedIUR.ElementTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.{Element, Metadata}

  test "builds canonical elements with stable identity and normalized metadata" do
    element =
      Element.new(:widget, :button,
        id: "save-button",
        metadata: [
          description: "Primary save action",
          annotations: [source: "spec"],
          tags: [:primary, :cta],
          extra: [variant: :solid]
        ],
        attributes: [label: "Save"],
        children: []
      )

    assert %Element{
             id: "save-button",
             type: :widget,
             kind: :button,
             attributes: %{label: "Save"},
             children: [],
             metadata: %Metadata{
               description: "Primary save action",
               annotations: %{source: "spec"},
               tags: [:primary, :cta],
               extra: %{variant: :solid}
             }
           } = element
  end

  test "metadata merge remains immutable and additive" do
    element =
      Element.new(:layout, :stack,
        metadata: [annotations: [source: "dsl"], tags: [:base], extra: [gap: 2]]
      )

    merged =
      Element.merge_metadata(element,
        description: "Main stack",
        annotations: [role: "primary"],
        tags: [:container],
        extra: [padding: 4]
      )

    assert element.metadata.description == nil
    assert element.metadata.annotations == %{source: "dsl"}
    assert element.metadata.tags == [:base]
    assert element.metadata.extra == %{gap: 2}

    assert merged.metadata.description == "Main stack"
    assert merged.metadata.annotations == %{source: "dsl", role: "primary"}
    assert merged.metadata.tags == [:base, :container]
    assert merged.metadata.extra == %{gap: 2, padding: 4}
  end

  test "metadata normalizes absent, partial, and extended values" do
    metadata =
      Metadata.new(%{
        "description" => "Toolbar actions",
        :annotations => [scope: "toolbar"],
        "tags" => [:toolbar, :toolbar, nil],
        "extra" => %{"slot" => :actions}
      })

    assert %Metadata{
             authored_ref: nil,
             description: "Toolbar actions",
             annotations: %{scope: "toolbar"},
             tags: [:toolbar],
             extra: %{"slot" => :actions}
           } = metadata
  end
end
