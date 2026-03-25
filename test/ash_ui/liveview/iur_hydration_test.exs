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
end
