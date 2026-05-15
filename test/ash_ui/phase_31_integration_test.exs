defmodule AshUI.Phase31IntegrationTest do
  use AshUI.DataCase, async: false

  @moduletag :conformance

  alias AshUI.Compilation.IUR
  alias AshUI.Compiler
  alias AshUI.DSL.Storage
  alias AshUI.LiveView.IURHydration
  alias AshUI.Rendering.{DesktopUIAdapter, ElmUIAdapter, IURAdapter, LiveUIAdapter}
  alias AshUI.Resource.Authority
  alias AshUI.Resources.Screen
  alias AshUI.Resources.Validations.Authoring
  alias AshUI.Test.Phase31RepeatScreen

  describe "Section 31.7 - Phase 31 integration tests" do
    test "supported component catalog, aliases, and admission align end to end" do
      assert AshUI.WidgetComponents.kinds() == UnifiedUi.WidgetComponents.kinds()
      assert AshUI.WidgetComponents.aliases() == UnifiedUi.WidgetComponents.aliases()

      for kind <- AshUI.WidgetComponents.kinds() do
        definition = %{type: kind, props: %{}, variants: [], metadata: %{}}
        dsl = %{type: Atom.to_string(kind), props: %{}, children: [], signals: [], metadata: %{}}

        assert Authoring.validate_element_definition!(definition) == definition
        assert Storage.validate_write(dsl) == :ok
      end

      for {alias_name, canonical_kind} <- AshUI.WidgetComponents.aliases() do
        assert Storage.canonical_widget_type(alias_name) == {:ok, Atom.to_string(canonical_kind)}
      end
    end

    test "representative component families compile, validate, and render through all adapters" do
      assert {:ok, canonical} = canonical_component_suite()
      assert {:ok, normalized} = UnifiedIUR.Normalize.element(canonical)
      assert :ok = UnifiedIUR.Validate.element(normalized)

      families =
        normalized.children
        |> Enum.map(& &1.element.attributes.component.family)
        |> MapSet.new()

      assert families == AshUI.WidgetComponents.families() |> Map.keys() |> MapSet.new()

      assert {:ok, heex} = LiveUIAdapter.render(canonical)
      assert heex =~ "data-live-ui-runtime"
      assert {:ok, %ElmUi.Widget{}} = ElmUIAdapter.render(canonical)
      assert {:ok, %DesktopUi.Widget{}} = DesktopUIAdapter.render(canonical)
    end

    test "relationship-owned list_repeat compiles to canonical metadata and hydrates row templates" do
      assert {:ok, attrs} =
               Authority.screen_attrs(Phase31RepeatScreen,
                 name: "phase_31_integration_repeat_screen"
               )

      assert {:ok, screen} = AshUI.Data.create(Screen, attrs: attrs)
      assert {:ok, iur} = Compiler.compile(screen, use_cache: false)
      assert [%{type: :list_repeat, children: [_template]} = repeat_iur] = iur.children
      assert repeat_iur.props["repeat_binding"] == "artifact_rows"

      assert {:ok, canonical} = IURAdapter.to_canonical(iur)

      hydrated =
        IURHydration.hydrate(canonical, %{
          "phase31_artifact_repeat" => %{
            element_id: "phase31_artifact_repeat",
            binding_type: :list,
            target: "artifact_rows",
            value: %{
              items: [
                %{
                  "id" => "adr-0007",
                  "title" => "Canonical widget components",
                  "status" => "accepted"
                }
              ],
              total: 1
            }
          }
        })

      [repeat] = hydrated["children"]
      [row] = repeat["children"]

      assert repeat["props"]["row_count"] == 1
      assert repeat["props"]["hydrated?"] == true
      assert row["props"]["row_identity"] == "adr-0007"
      assert row["props"]["title"] == "Canonical widget components"
      assert row["props"]["meta"]["status"] == "accepted"
    end
  end

  defp canonical_component_suite do
    IUR.new(:screen,
      id: "phase-31-component-suite",
      name: "phase_31_component_suite",
      children: [
        IUR.new(:inline_rich_text_heading,
          id: "heading",
          props: %{level: :h2, segments: [%{type: :text, value: "Phase 31"}]}
        ),
        IUR.new(:runtime_form_shell,
          id: "form-shell",
          props: %{fields: [%{name: :email, label: "Email"}], submit_label: "Save"}
        ),
        IUR.new(:artifact_row,
          id: "artifact-row",
          props: %{
            row_identity: "adr-0007",
            title: "Canonical widgets",
            meta: %{status: :accepted}
          }
        ),
        IUR.new(:pipeline_stepper_horizontal,
          id: "pipeline",
          props: %{steps: [%{id: :draft, label: "Draft"}], active_index: 0}
        ),
        IUR.new(:event_callout,
          id: "callout",
          props: %{message: "Component fallback stays semantic", tone: :info}
        ),
        IUR.new(:code_block_syntax_highlighted,
          id: "code",
          props: %{language: :elixir, tokens: [%{type: :keyword, text: "defmodule"}]}
        ),
        IUR.new(:list_repeat,
          id: "repeat",
          props: %{repeat_binding: :rows, row_scope: :row, row_fields: [:id], row_count: 0},
          children: [
            IUR.new(:artifact_row, id: "repeat-template", props: %{title: "Template"})
          ]
        )
      ]
    )
    |> IURAdapter.to_canonical()
  end
end
