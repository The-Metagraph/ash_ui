defmodule LiveUi.DocumentationAlignmentTest do
  use ExUnit.Case, async: true

  test "documentation surface describes aligned examples and omits retired demo language" do
    docs = LiveUi.Tooling.documentation_surface()

    assert docs.complete?
    assert docs.missing_paths == []
    assert docs.missing_snippets == %{}
    assert docs.prohibited_mentions == []
  end
end
