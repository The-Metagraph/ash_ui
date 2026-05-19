defmodule AshUI.Rendering.IURAdapterTest do
  use AshUI.DataCase, async: false

  @moduletag :conformance

  alias AshUI.Compilation.IUR
  alias AshUI.Compiler
  alias AshUI.Rendering.IURAdapter
  alias AshUI.Resource.Authority
  alias AshUI.Test.{ResourceAuthorityScreen, UIStorageFixtures}

  describe "to_canonical/1" do
    test "converts simple screen to canonical format" do
      ash_iur =
        IUR.new(:screen,
          id: "test-screen-1",
          name: "test_screen",
          attributes: %{
            "layout" => :row,
            "route" => "/test"
          },
          children: [
            IUR.new(:text,
              id: "text-1",
              props: %{"content" => "Hello World"}
            )
          ]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)

      assert canonical.type == :composite
      assert canonical.kind == :screen
      assert canonical.id == "test-screen-1"
      assert canonical.attributes.screen.name == "test_screen"
      assert canonical.attributes.screen.layout == :row
      assert is_list(canonical.children)
      assert length(canonical.children) == 1
      assert_valid_canonical(canonical)
    end

    test "converts element to canonical widget type" do
      element = IUR.new(:button, props: %{"label" => "Click me"})

      ash_iur =
        IUR.new(:screen,
          children: [element]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)

      [child] = canonical.children
      assert child.element.type == :widget
      assert child.element.kind == :button
      assert child.element.attributes.content.text == "Click me"
    end

    test "converts layout to canonical layout type" do
      layouts = [:row, :column, :grid, :stack]

      Enum.each(layouts, fn layout ->
        ash_iur =
          IUR.new(:screen,
            attributes: %{"layout" => layout}
          )

        assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
        assert canonical.attributes.screen.layout == layout
      end)
    end

    test "converts nested elements" do
      ash_iur =
        IUR.new(:screen,
          attributes: %{"layout" => :column},
          children: [
            IUR.new(:row,
              children: [
                IUR.new(:text, props: %{"content" => "Nested"}),
                IUR.new(:button, props: %{"label" => "Button"})
              ]
            )
          ]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)

      [row] = canonical.children
      assert row.element.kind == :row

      assert length(row.element.children) == 2
    end
  end

  describe "compatible?/2" do
    test "returns true for screen with valid renderers" do
      screen_iur = IUR.new(:screen)

      assert IURAdapter.compatible?(screen_iur, :live_ui)
      assert IURAdapter.compatible?(screen_iur, :elm)
      assert IURAdapter.compatible?(screen_iur, :desktop_ui)
    end

    test "returns false for non-screen types" do
      text_iur = IUR.new(:text)

      refute IURAdapter.compatible?(text_iur, :live_ui)
    end
  end

  describe "element type mapping" do
    test "maps known element types correctly" do
      type_mappings = [
        {:text, :text},
        {:button, :button},
        {:textinput, :text_input},
        {:textarea, :text_input},
        {:select, :select},
        {:row, :row},
        {:column, :column}
      ]

      Enum.each(type_mappings, fn {ash_type, expected_canonical} ->
        ash_iur =
          IUR.new(:screen,
            children: [IUR.new(ash_type)]
          )

        assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
        [child] = canonical.children
        assert child.element.kind == expected_canonical
      end)
    end
  end

  describe "props mapping" do
    test "converts props map correctly" do
      ash_iur =
        IUR.new(:screen,
          children: [
            IUR.new(:button,
              props: %{
                "label" => "Submit",
                "disabled" => false
              }
            )
          ]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)

      [child] = canonical.children
      assert child.element.attributes.content.text == "Submit"
      assert child.element.attributes.button.disabled == false
    end

    test "preserves empty binding paths on authored form widgets" do
      ash_iur =
        IUR.new(:screen,
          children: [
            IUR.new(:form_field,
              props: %{
                "bindings" => [
                  %{
                    "name" => :display_name,
                    "path" => [],
                    "scope" => [],
                    "depends_on" => [],
                    "metadata" => [],
                    "derived" => []
                  }
                ]
              }
            )
          ]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
      assert_valid_canonical(canonical)
    end

    test "converts resource-authority semantic widgets without leaking renderer assumptions" do
      ui_storage = UIStorageFixtures.ui_storage_config()

      assert {:ok, screen} =
               Authority.create(ResourceAuthorityScreen,
                 ui_storage: ui_storage,
                 route: "/phase-13/resource-authority",
                 layout: :column,
                 metadata: %{"seed" => "phase13"}
               )

      assert {:ok, ash_iur} = Compiler.compile(screen, ui_storage: ui_storage, use_cache: false)
      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
      assert_valid_canonical(canonical)

      kinds = collect_kinds(canonical)

      assert :hero in kinds
      assert :stat in kinds
      assert :key_value in kinds
      assert :info_list in kinds
      assert :form_field in kinds

      assert get_in(canonical.metadata.extra, ["ash_ui", "ash_ui", "compiler_boundary"]) ==
               "AshUI resource graph -> AshUI runtime normalization"

      refute Enum.any?(canonical.children, fn child ->
               Map.has_key?(child.element.metadata.annotations, :ash_ui)
             end)
    end
  end

  describe "ask_sidebar IUR routing" do
    test "routes ask_sidebar kind through layer_shell_and_callout family" do
      ash_iur =
        IUR.new(:screen,
          id: "ask-sidebar-screen",
          name: "ask_sidebar_screen",
          attributes: %{},
          children: [
            IUR.new(:ask_sidebar,
              id: "ask-sb-1",
              props: %{
                "sidebar_id" => "main-ask-sidebar",
                "on_map_jump_event" => "switch_to_map"
              }
            )
          ]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
      [child] = canonical.children
      assert child.element.kind == :ask_sidebar
      assert child.element.type == :widget
      assert child.element.attributes.component.family == :layer_shell_and_callout
    end

    test "preserves sidebar_id in canonical ask_sidebar attributes" do
      ash_iur =
        IUR.new(:screen,
          id: "ask-sidebar-screen-2",
          name: "ask_sidebar_screen",
          attributes: %{},
          children: [
            IUR.new(:ask_sidebar,
              id: "ask-sb-2",
              props: %{
                "sidebar_id" => "workspace-ask-sidebar",
                "on_map_jump_event" => "goto_map"
              }
            )
          ]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
      [child] = canonical.children
      assert child.element.attributes.ask_sidebar.sidebar_id == "workspace-ask-sidebar"
      assert child.element.attributes.ask_sidebar.on_map_jump_event == "goto_map"
    end
  end

  describe "workflow_progress_status_card IUR routing" do
    test "routes workflow_progress_status_card kind through workflow_progress_and_status family" do
      ash_iur =
        IUR.new(:screen,
          id: "subject-card-screen",
          name: "subject_card_screen",
          attributes: %{},
          children: [
            IUR.new(:workflow_progress_status_card,
              id: "rpc-1",
              props: %{
                "name" => "metagraph",
                "progress_pct" => 0.5,
                "active_count" => 2,
                "blocked_count" => 0
              }
            )
          ]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
      [child] = canonical.children
      assert child.element.kind == :workflow_progress_status_card
      assert child.element.type == :widget
      assert child.element.attributes.component.family == :workflow_progress_and_status
      assert :ok = UnifiedIUR.Validate.element(child.element)
    end

    test "maps subject props into canonical attributes without namespace overwrite" do
      ash_iur =
        IUR.new(:screen,
          id: "subject-card-screen-2",
          name: "subject_card_screen",
          attributes: %{},
          children: [
            IUR.new(:workflow_progress_status_card,
              id: "rpc-2",
              props: %{
                "name" => "ash_ui",
                "subject_id" => "subject:ash_ui",
                "path" => "workspaces/ash_ui",
                "progress_pct" => 0.72,
                "active_count" => 4,
                "blocked_count" => 1,
                "last_activity_at" => ~U[2026-05-19 10:00:00Z],
                "depends_on" => ["unified_iur"],
                "depended_by" => [%{"id" => "ariston-ui", "label" => "Ariston UI"}],
                "selected?" => true,
                "open_action" => %{"label" => "Open", "intent" => "open_subject"},
                "component" => %{"family" => "bad_family"},
                "subject" => %{"name" => "bad_subject"}
              }
            )
          ]
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur)
      [child] = canonical.children

      assert child.element.attributes.component == %{
               family: :workflow_progress_and_status,
               kind: :workflow_progress_status_card
             }

      assert child.element.attributes.subject.id == "subject:ash_ui"
      assert child.element.attributes.subject.name == "ash_ui"
      assert child.element.attributes.subject.path == "workspaces/ash_ui"
      assert child.element.attributes.subject.progress == 72.0
      assert child.element.attributes.subject.status_counts == %{active: 4, blocked: 1}

      assert child.element.attributes.subject.activity == %{
               last_activity_at: ~U[2026-05-19 10:00:00Z]
             }

      assert child.element.attributes.subject.dependencies == %{
               depends_on: [%{id: "unified_iur", label: "unified_iur", direction: :depends_on}],
               depended_by: [
                 %{id: "ariston-ui", label: "Ariston UI", direction: :depended_by}
               ]
             }

      assert child.element.attributes.subject.state == %{selected?: true}

      assert child.element.attributes.subject.actions.open == %{
               label: "Open",
               intent: "open_subject"
             }

      assert child.element.attributes.subject.interactions.focus.intent == "focus_subject"
      assert :ok = UnifiedIUR.Validate.element(child.element)
    end

    test "returns structured conversion errors for invalid subject cards" do
      ash_iur =
        IUR.new(:screen,
          id: "subject-card-screen-3",
          name: "subject_card_screen",
          attributes: %{},
          children: [
            IUR.new(:workflow_progress_status_card,
              id: "rpc-3",
              props: %{"name" => "ash_ui", "progress" => 150}
            )
          ]
        )

      assert {:error, {:conversion_failed, %ArgumentError{} = error}} =
               IURAdapter.to_canonical(ash_iur)

      assert error.message =~ "progress must be in 0.0..100.0"
    end
  end

  describe "error handling" do
    test "returns error for invalid IUR" do
      invalid_iur = %IUR{type: nil}

      assert {:error, _reason} = IURAdapter.to_canonical(invalid_iur)
    end
  end

  defp assert_valid_canonical(canonical) do
    assert {:ok, %UnifiedIUR.Element{} = normalized} = UnifiedIUR.Normalize.element(canonical)
    assert :ok = UnifiedIUR.Validate.element(normalized)
  end

  defp collect_kinds(%UnifiedIUR.Element{kind: kind, children: children}) do
    [kind | Enum.flat_map(children || [], &collect_kinds/1)]
  end

  defp collect_kinds(%UnifiedIUR.Element.Child{element: nil}), do: []

  defp collect_kinds(%UnifiedIUR.Element.Child{element: element}) do
    collect_kinds(element)
  end

  defp collect_kinds(_other), do: []
end
