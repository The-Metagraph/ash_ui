defmodule UnifiedUi.DisplaySystemsTest do
  use ExUnit.Case, async: true

  alias Spark.Dsl.Extension

  defmodule ViewportStudio do
    use UnifiedUi.Dsl

    identity do
      id(:viewport_studio)
      authored_ref([:examples, :viewport_studio])
    end

    composition do
      root(:viewport_studio_root)
      mode(:screen)

      box :document_panel do
        text :document_copy do
          value("Document body")
        end
      end

      box :floating_panel do
        text :floating_copy do
          value("Floating note")
        end
      end

      column :display_shell do
        viewport :document_viewport do
          content_ref(:document_panel)
          width(80)
          height(24)
          offset({0, 12})
          clip?(true)
        end

        scroll_region :activity_region do
          content_ref(:document_panel)
          height(18)
          offset(8)
        end

        canvas :activity_canvas do
          width(80)
          height(24)

          operations([
            [kind: :cell, position: {0, 0}, text: "X"],
            [kind: :fragment, position: {3, 2}, text: "Legend"]
          ])
        end
      end

      toast :floating_note do
        message("Note ready")
        severity(:info)
      end

      overlay :document_overlay do
        base_ref(:document_panel)
        layer_refs([:floating_note])
        background_fill(:scrim)
      end

      absolute :floating_badge do
        content_ref(:floating_panel)
        target_ref(:document_panel)
        x(12)
        y(4)
        z_index(3)
      end
    end
  end

  test "registers viewport, layer, and canvas kinds for package inspection" do
    assert UnifiedUi.Display.kinds() == [:scroll_bar, :split_pane, :viewport, :scroll_region]

    assert UnifiedUi.Layer.kinds() == [
             :context_menu,
             :dialog,
             :alert_dialog,
             :toast,
             :overlay,
             :absolute
           ]

    assert UnifiedUi.Canvas.kinds() == [:canvas]
  end

  test "allows display-system nodes inside authored layout shells and top-level layer declarations" do
    nodes = Extension.get_entities(ViewportStudio, [:composition])
    [_, _, shell, note, overlay, absolute] = nodes

    assert {shell.family, shell.kind} == {:layout, :column}

    assert Enum.map(shell.children, &{&1.id, &1.family, &1.kind}) == [
             {:document_viewport, :display, :viewport},
             {:activity_region, :display, :scroll_region},
             {:activity_canvas, :canvas, :canvas}
           ]

    assert {note.family, note.kind} == {:overlay, :toast}
    assert {overlay.family, overlay.kind} == {:overlay, :overlay}
    assert {absolute.family, absolute.kind} == {:overlay, :absolute}
  end

  test "summarizes viewport, overlay, absolute, and canvas declarations through the public inspection helpers" do
    assert UnifiedUi.Info.composition_summary(ViewportStudio) == [
             %{
               id: :document_panel,
               family: :layout,
               kind: :box,
               children: [
                 %{
                   id: :document_copy,
                   family: :foundational,
                   kind: :text,
                   role: :text,
                   value: "Document body"
                 }
               ]
             },
             %{
               id: :floating_panel,
               family: :layout,
               kind: :box,
               children: [
                 %{
                   id: :floating_copy,
                   family: :foundational,
                   kind: :text,
                   role: :text,
                   value: "Floating note"
                 }
               ]
             },
             %{
               id: :display_shell,
               family: :layout,
               kind: :column,
               children: [
                 %{
                   id: :document_viewport,
                   family: :display,
                   kind: :viewport,
                   content_ref: :document_panel,
                   offset: {0, 12},
                   clip?: true
                 },
                 %{
                   id: :activity_region,
                   family: :display,
                   kind: :scroll_region,
                   content_ref: :document_panel,
                   offset: 8,
                   clip?: true
                 },
                 %{
                   id: :activity_canvas,
                   family: :canvas,
                   kind: :canvas,
                   operations: [
                     [kind: :cell, position: {0, 0}, text: "X"],
                     [kind: :fragment, position: {3, 2}, text: "Legend"]
                   ]
                 }
               ]
             },
             %{
               id: :floating_note,
               family: :overlay,
               kind: :toast,
               message: "Note ready",
               severity: :info,
               placement: :bottom_end
             },
             %{
               id: :document_overlay,
               family: :overlay,
               kind: :overlay,
               base_ref: :document_panel,
               layer_refs: [:floating_note],
               background_fill: :scrim
             },
             %{
               id: :floating_badge,
               family: :overlay,
               kind: :absolute,
               content_ref: :floating_panel,
               target_ref: :document_panel,
               x: 12,
               y: 4,
               z_index: 3
             }
           ]
  end
end
