defmodule UnifiedUi.CompilerInspectionTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Reference, as: IURReference
  alias UnifiedUi.{Compiler, Info, Reference}

  defmodule InspectableWorkspace do
    use UnifiedUi.Dsl

    identity do
      id(:inspectable_workspace)
      title("Inspectable Workspace")
      authored_ref([:tests, :inspectable_workspace])
      tags([:compiler, :inspection, :phase_5])
    end

    themes do
      default_theme(:workspace)

      theme do
        id(:workspace)

        palette_color do
          id(:surface)
          color(named_color(:black))
        end

        semantic_role do
          id(:primary_text)
          value(named_color(:white))
        end

        component_style do
          id(:panel_shell)
          component(:box)

          style(
            style_value(
              background: token_ref(:surface),
              foreground: role_ref(:primary_text)
            )
          )
        end
      end
    end

    composition do
      root(:inspectable_workspace_root)
      mode(:screen)

      box :shell do
        theme_ref(:workspace)
        style_refs([:panel_shell])

        text :headline do
          value("Inspection ready")
        end

        button :save_button do
          label("Save")
          interaction_refs([:save_profile])
        end
      end

      dialog :confirm_dialog do
        title("Confirm")
        content_ref(:shell)
        trigger_ref(:save_button)
        visible?(true)
        confirm_intent(:save_profile)
      end

      scroll_bar :workspace_scroll do
        target_ref(:shell)
        position(4)
        viewport_size(12)
        content_size(48)
      end
    end

    signals do
      namespace(:workspace)

      data_binding do
        id(:profile_data)
        path([:profile])
        scope([:screen])
        default(%{display_name: ""})
      end

      interaction do
        id(:save_profile)
        family(:submit)
        intent(:save_profile)
        source_context(element_id: :save_button, scope: :screen)
        target_intent(binding: :profile_data, entity: :profile)
        payload_mapping(profile: binding_ref(:profile_data))
        binding_refs([:profile_data])
      end
    end
  end

  test "lists compiled constructs, themes, bindings, signals, and authored traces" do
    listing = Compiler.listing(InspectableWorkspace)

    assert listing.module == InspectableWorkspace

    assert listing.authored == %{
             identity_id: :inspectable_workspace,
             authored_ref: [:tests, :inspectable_workspace],
             authored_ids: [:confirm_dialog, :headline, :save_button, :shell, :workspace_scroll],
             style_ref_ids: [:panel_shell],
             themed_node_ids: [:shell]
           }

    assert listing.compiled.element_types == [:composite, :layer, :layout, :widget]
    assert listing.compiled.widget_kinds == [:button, :scroll_bar, :text]
    assert listing.compiled.layout_kinds == [:box]
    assert listing.compiled.composite_kinds == [:screen]
    assert listing.compiled.layer_kinds == [:dialog]

    assert listing.compiled.display_systems == %{
             layer_kinds: [:dialog],
             viewport_kinds: [:scroll_bar],
             canvas_kinds: [],
             layered?: true,
             viewport?: true,
             canvas?: false
           }

    assert listing.themes == %{
             default_theme: :workspace,
             theme_ids: [:workspace],
             style_ref_ids: [:panel_shell],
             themed_element_ids: [:shell]
           }

    assert listing.bindings == %{
             names: [:profile_data],
             paths: [[:profile]],
             scopes: [[:screen]]
           }

    assert listing.signals == %{
             ids: [:save_profile],
             families: [:submit],
             intents: [:save_profile],
             source_element_ids: [:save_button],
             target_bindings: [:profile_data]
           }

    assert Enum.any?(listing.trace.authored_to_compiled, fn trace ->
             trace == %{authored_id: :shell, compiled_id: :shell, type: :layout, kind: :box}
           end)
  end

  test "builds deterministic inspection reports and review-friendly output" do
    report = Compiler.inspection(InspectableWorkspace)
    report_again = Compiler.inspection(InspectableWorkspace)
    rendered = Compiler.render_inspection(InspectableWorkspace)

    assert report.summary == report_again.summary
    assert report.listing == report_again.listing
    assert report.render_tree == report_again.render_tree
    assert report.snapshot == report_again.snapshot

    assert report.render_tree ==
             String.trim_trailing("""
             - inspectable_workspace_root [composite:screen]
               @default
                 - shell [layout:box]
                   @default
                     - headline [widget:text]
                   @default
                     - save_button [widget:button]
               @default
                 - confirm_dialog [layer:dialog]
                   @content
                     - shell [layout:box]
                       @default
                         - headline [widget:text]
                       @default
                         - save_button [widget:button]
               @default
                 - workspace_scroll [widget:scroll_bar]
             """)

    assert report.snapshot == IURReference.snapshot(Compiler.iur!(InspectableWorkspace))
    assert rendered =~ "UnifiedUi compiler inspection"
    assert rendered =~ "widget kinds: [:button, :scroll_bar, :text]"
    assert rendered =~ "signal families: [:submit]"
    assert rendered =~ "trace authored->compiled:"
    assert rendered =~ report.render_tree
  end

  test "reports supported compiled construct families through reference helpers" do
    compiled_families = Reference.compiled_construct_families()

    assert compiled_families == %{
             element_types: [:widget, :layout, :layer, :style, :theme, :interaction, :composite],
             widgets: %{
               foundational: UnifiedIUR.Widgets.foundational_kinds(),
               input: UnifiedIUR.Widgets.input_kinds(),
               navigation: UnifiedIUR.Widgets.navigation_kinds(),
               data: UnifiedIUR.Widgets.data_view_kinds(),
               feedback: UnifiedIUR.Widgets.feedback_kinds(),
               advanced: UnifiedIUR.Widgets.advanced_kinds(),
               forms: UnifiedIUR.Forms.kinds(),
               container: [:box]
             },
             display: %{
               layout: UnifiedIUR.Layout.kinds(),
               layer: UnifiedIUR.Layer.kinds(),
               viewport: UnifiedIUR.Viewport.kinds(),
               canvas: UnifiedIUR.Canvas.kinds()
             },
             signals: UnifiedIUR.Interaction.families()
           }

    assert Info.supported_compiled_construct_families() == compiled_families
  end
end
