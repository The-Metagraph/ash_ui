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

  # Issue #114: two-level IUR where the repeat-marked template node has a
  # widget type other than "list_repeat" (e.g. "custom:doc_block_numbered")
  # and the list binding is screen-scoped (not element-scoped).  The
  # `expand_repeat_template/2` path in IURHydration must traverse this shape
  # and fan-out one cloned row per item.
  test "expands repeat-marked non-list_repeat nodes using screen-scoped list binding" do
    iur = %{
      "type" => "screen",
      "children" => [
        %{
          "id" => "doc-block-template",
          "type" => "custom:doc_block_numbered",
          "props" => %{
            "block_id" => %{"scope" => "row", "field" => "id"},
            "text" => %{"scope" => "row", "field" => "text"}
          },
          "children" => [],
          "metadata" => %{
            "composition" => %{
              "kind" => "child",
              "name" => "doc_blocks",
              "type" => "has_many",
              "repeat" => %{
                "binding_id" => "doc_blocks_rows",
                "row_scope" => "row",
                "row_fields" => ["id", "text"]
              }
            }
          }
        }
      ]
    }

    # Screen-scoped binding (owner_scope: "screen") — filtered out of the
    # element-scoped hydration pass but must still reach expand_repeat_template.
    bindings = %{
      "doc_blocks_rows" => %{
        id: "doc_blocks_rows",
        target: "screen.doc_blocks_rows",
        binding_type: :list,
        metadata: %{"owner_scope" => "screen"},
        value: [
          %{"id" => "block-1", "text" => "First paragraph."},
          %{"id" => "block-2", "text" => "Second paragraph."},
          %{"id" => "block-3", "text" => "Third paragraph."}
        ]
      }
    }

    hydrated = IURHydration.hydrate(iur, bindings)
    [wrapper] = hydrated["children"]

    # The template node is replaced by a synthetic list_repeat wrapper.
    assert wrapper["type"] == "list_repeat"
    assert wrapper["props"]["hydrated?"] == true
    assert wrapper["props"]["row_count"] == 3

    # Three row instances cloned from the template.
    assert length(wrapper["children"]) == 3

    [row1, row2, row3] = wrapper["children"]

    # Each row resolves its row-scoped field references.
    assert row1["props"]["text"] == "First paragraph."
    assert row2["props"]["text"] == "Second paragraph."
    assert row3["props"]["text"] == "Third paragraph."

    assert row1["props"]["block_id"] == "block-1"
    assert row2["props"]["block_id"] == "block-2"
    assert row3["props"]["block_id"] == "block-3"

    # Repeat metadata is stripped from cloned rows so they do not re-expand.
    refute get_in(row1, ["metadata", "composition", "repeat"])
    refute get_in(row2, ["metadata", "composition", "repeat"])
    refute get_in(row3, ["metadata", "composition", "repeat"])
  end
end
