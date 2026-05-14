defmodule DesktopUi.RendererTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Element
  alias UnifiedIUR.Element.Child

  test "renderer maps foundational canonical widgets and layouts into native desktop widgets" do
    element =
      Element.new(:layout, :column,
        id: "workspace-layout",
        attributes: %{gap: 16},
        children: [
          Element.new(:widget, :text,
            id: "workspace-title",
            attributes: %{content: "Workspace"}
          ),
          Element.new(:widget, :text_input,
            id: "query-input",
            attributes: %{
              value: "status:ok",
              placeholder: "Search",
              binding: %{name: :query, value: "status:ok"},
              interaction: %{family: :submit, intent: :run_query}
            }
          ),
          Element.new(:widget, :tabs,
            id: "workspace-tabs",
            attributes: %{
              items: [%{id: :overview, label: "Overview"}, %{id: :activity, label: "Activity"}],
              current: :overview,
              binding: %{name: :section, value: :overview},
              interaction: %{family: :navigation, intent: :switch_section}
            }
          ),
          Element.new(:widget, :button,
            id: "save-button",
            attributes: %{label: "Save", interaction: %{family: :click, intent: :save_workspace}}
          )
        ]
      )

    assert {:ok, widget} = DesktopUi.Renderer.render(element)
    assert widget.kind == :column
    assert Enum.map(widget.children, & &1.kind) == [:text, :text_input, :tabs, :button]
    assert Enum.at(widget.children, 1).bindings.value == :query
    assert Enum.at(widget.children, 2).bindings.current == :section
    assert Enum.at(widget.children, 3).events.click.intent == :save_workspace
    assert DesktopUi.Renderer.validation_state() == :advanced_mapper_ready
  end

  test "renderer maps advanced canonical widgets, display systems, and layers into native desktop widgets" do
    element =
      Element.new(:layer, :multi_window,
        id: "operations-windows",
        children: [
          Element.new(:widget, :window,
            id: "operations-window",
            attributes: %{title: "Operations"},
            children: [
              Element.new(:layer, :overlay,
                id: "operations-overlay",
                children: [
                  Child.new(
                    :content,
                    Element.new(:layout, :split_pane,
                      id: "operations-split",
                      attributes: %{ratio: 0.6},
                      children: [
                        Child.new(
                          :primary,
                          Element.new(:layout, :viewport,
                            id: "services-viewport",
                            children: [
                              Child.new(
                                :content,
                                Element.new(:widget, :table,
                                  id: "services-table",
                                  attributes: %{
                                    columns: [%{id: :service, label: "Service"}],
                                    rows: [%{id: :api, cells: ["API"]}],
                                    binding: %{name: :selected_service, value: :api}
                                  }
                                )
                              )
                            ]
                          )
                        ),
                        Child.new(
                          :secondary,
                          Element.new(:widget, :command_palette,
                            id: "ops-palette",
                            attributes: %{
                              commands: [%{id: :reload, label: "Reload"}],
                              query: "re",
                              binding: %{name: :command_query, value: "re"},
                              interaction: %{family: :command, intent: :run_command}
                            }
                          )
                        )
                      ]
                    )
                  ),
                  Child.new(
                    :overlay,
                    Element.new(:widget, :dialog,
                      id: "ops-dialog",
                      attributes: %{title: "Runbook"}
                    )
                  )
                ]
              )
            ]
          ),
          Element.new(:widget, :window,
            id: "details-window",
            attributes: %{title: "Details"},
            children: [
              Element.new(:widget, :process_monitor,
                id: "process-monitor",
                attributes: %{
                  processes: [%{id: :beam, name: "beam.smp"}],
                  binding: %{name: :selected_process, value: :beam}
                }
              )
            ]
          )
        ]
      )

    assert {:ok, widget} = DesktopUi.Renderer.render(element)
    assert widget.kind == :multi_window
    assert Enum.any?(widget.children, &(&1.kind == :window))

    operations_window = Enum.find(widget.children, &(&1.id == "operations-window"))
    overlay = List.first(operations_window.children)
    split_pane = List.first(overlay.slot_children.content)
    viewport = List.first(split_pane.slot_children.primary)
    table = List.first(viewport.slot_children.content)

    assert overlay.kind == :overlay
    assert split_pane.kind == :split_pane
    assert viewport.kind == :viewport
    assert table.kind == :table
    assert table.bindings.selection == :selected_service
  end

  test "renderer rejects unsupported canonical constructs and invalid bindings deterministically" do
    unsupported = Element.new(:widget, :calendar, id: "unsupported-calendar")

    assert {:error, %DesktopUi.Renderer.Error{} = unsupported_error} =
             DesktopUi.Renderer.render(unsupported)

    assert unsupported_error.reason == :unsupported_canonical_construct
    assert unsupported_error.details.kind == :calendar

    invalid_bindings =
      Element.new(:widget, :text_input,
        id: "query",
        attributes: %{binding: %{invalid: true}}
      )

    assert {:error, %DesktopUi.Renderer.Error{} = invalid_binding_error} =
             DesktopUi.Renderer.render(invalid_bindings)

    assert invalid_binding_error.reason == :invalid_canonical_bindings
    assert invalid_binding_error.details.id == "query"
  end
end
