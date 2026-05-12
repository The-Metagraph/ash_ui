defmodule AshUI.LiveView.IURHydrationTest do
  use ExUnit.Case, async: true

  alias AshUI.LiveView.IURHydration

  test "hydrates input widgets from authored runtime bindings" do
    iur = %{
      "type" => "screen",
      "children" => [
        %{
          "id" => "display_name_input",
          "type" => "input",
          "props" => %{"placeholder" => "Name"}
        }
      ]
    }

    bindings = %{
      "display_name_input" => %{
        element_id: "display_name_input",
        target: "display_name",
        binding_type: :value,
        value: "Pascal"
      }
    }

    hydrated = IURHydration.hydrate(iur, bindings)
    [input] = hydrated["children"]

    assert input["props"]["value"] == "Pascal"
  end

  test "hydrates list widgets from collection binding results" do
    iur = %{
      "type" => "screen",
      "children" => [
        %{
          "id" => "comments_table",
          "type" => "table",
          "props" => %{"items" => []}
        }
      ]
    }

    bindings = %{
      "comments_table" => %{
        element_id: "comments_table",
        target: "comments",
        binding_type: :list,
        value: %{
          items: [%{"id" => "comment-1", "content" => "First"}],
          total: 1,
          page: 1
        }
      }
    }

    hydrated = IURHydration.hydrate(iur, bindings)
    [table] = hydrated["children"]

    assert table["props"]["items"] == [%{"id" => "comment-1", "content" => "First"}]
    assert table["props"]["collection"]["total"] == 1
  end

  describe "repeat expansion" do
    test "fans a single template child out to one IUR node per row" do
      iur = %{
        "type" => "screen",
        "children" => [
          %{
            "id" => "manuscript_block_template",
            "type" => "text",
            "props" => %{"content" => "placeholder"},
            "metadata" => %{
              "composition" => %{"repeat" => "manuscript_block_rows"}
            }
          }
        ]
      }

      bindings = %{
        "manuscript_block_rows" => %{
          id: "manuscript_block_rows",
          element_id: nil,
          target: "screen.manuscript_block_rows",
          binding_type: :list,
          value: [
            %{"id" => "block-1", "title" => "Introduction"},
            %{"id" => "block-2", "title" => "Method"},
            %{"id" => "block-3", "title" => "Results"}
          ],
          metadata: %{"owner_scope" => "screen"}
        }
      }

      hydrated = IURHydration.hydrate(iur, bindings)

      assert length(hydrated["children"]) == 3

      ids = Enum.map(hydrated["children"], & &1["id"])

      assert ids == [
               "manuscript_block_template__row_block-1",
               "manuscript_block_template__row_block-2",
               "manuscript_block_template__row_block-3"
             ]

      Enum.each(hydrated["children"], fn clone ->
        composition = clone["metadata"]["composition"]
        # The template clone must not carry an active `repeat` marker, or it
        # would re-expand forever.
        refute Map.has_key?(composition, "repeat")
        assert composition["repeat_origin"] == "manuscript_block_rows"
        assert is_integer(composition["repeat_row_index"])
      end)
    end

    test "projects scope:row field bindings onto the clone's hydrated props" do
      iur = %{
        "type" => "screen",
        "children" => [
          %{
            "id" => "row_template",
            "type" => "text",
            "props" => %{"content" => "placeholder"},
            "metadata" => %{
              "composition" => %{"repeat" => "rows_binding"}
            },
            "bindings" => [
              %{
                "source" => %{"scope" => "row", "field" => "title"},
                "target" => "content"
              }
            ]
          }
        ]
      }

      bindings = %{
        "rows_binding" => %{
          id: "rows_binding",
          element_id: nil,
          target: "screen.rows_binding",
          binding_type: :list,
          value: [
            %{"id" => "r1", "title" => "Hello"},
            %{"id" => "r2", "title" => "World"}
          ],
          metadata: %{"owner_scope" => "screen"}
        }
      }

      hydrated = IURHydration.hydrate(iur, bindings)
      [clone_one, clone_two] = hydrated["children"]

      assert clone_one["props"]["content"] == "Hello"
      assert clone_two["props"]["content"] == "World"

      # Each clone also exposes the whole row under `props["row"]` so widgets
      # downstream can access it without authoring a per-field binding.
      assert clone_one["props"]["row"]["title"] == "Hello"
      assert clone_two["props"]["row"]["title"] == "World"
    end

    test "an empty row list yields zero children" do
      iur = %{
        "type" => "screen",
        "children" => [
          %{
            "id" => "template",
            "type" => "text",
            "props" => %{},
            "metadata" => %{"composition" => %{"repeat" => "empty_rows"}}
          }
        ]
      }

      bindings = %{
        "empty_rows" => %{
          id: "empty_rows",
          element_id: nil,
          target: "screen.empty_rows",
          binding_type: :list,
          value: [],
          metadata: %{"owner_scope" => "screen"}
        }
      }

      hydrated = IURHydration.hydrate(iur, bindings)
      assert hydrated["children"] == []
    end

    test "a missing binding for the repeat id yields zero children" do
      iur = %{
        "type" => "screen",
        "children" => [
          %{
            "id" => "template",
            "type" => "text",
            "props" => %{},
            "metadata" => %{"composition" => %{"repeat" => "absent_binding"}}
          }
        ]
      }

      hydrated = IURHydration.hydrate(iur, %{})
      assert hydrated["children"] == []
    end

    test "accepts the %{\"items\" => [...]} list-collection shape too" do
      iur = %{
        "type" => "screen",
        "children" => [
          %{
            "id" => "template",
            "type" => "text",
            "props" => %{},
            "metadata" => %{"composition" => %{"repeat" => "rows"}}
          }
        ]
      }

      bindings = %{
        "rows" => %{
          id: "rows",
          element_id: nil,
          target: "screen.rows",
          binding_type: :list,
          value: %{"items" => [%{"id" => "x"}, %{"id" => "y"}]},
          metadata: %{"owner_scope" => "screen"}
        }
      }

      hydrated = IURHydration.hydrate(iur, bindings)
      assert length(hydrated["children"]) == 2
    end
  end

  describe "repeat expansion → live_ui renderer pipeline" do
    test "the live_ui renderer emits N rendered children for an N-row repeat" do
      iur = %{
        "type" => "screen",
        "id" => "screen-1",
        "name" => "manuscript",
        "children" => [
          %{
            "id" => "block",
            "type" => "text",
            "props" => %{"content" => "placeholder"},
            "metadata" => %{
              "composition" => %{"repeat" => "blocks_rows"}
            },
            "bindings" => [
              %{
                "source" => %{"scope" => "row", "field" => "title"},
                "target" => "content"
              }
            ]
          }
        ]
      }

      bindings = %{
        "blocks_rows" => %{
          id: "blocks_rows",
          element_id: nil,
          target: "screen.blocks_rows",
          binding_type: :list,
          value: [
            %{"id" => "b1", "title" => "Alpha"},
            %{"id" => "b2", "title" => "Beta"}
          ],
          metadata: %{"owner_scope" => "screen"}
        }
      }

      hydrated = IURHydration.hydrate(iur, bindings)

      assert {:ok, heex} = LiveUI.Renderer.render(hydrated)
      assert heex =~ "Alpha"
      assert heex =~ "Beta"
      refute heex =~ "placeholder"
    end
  end
end
