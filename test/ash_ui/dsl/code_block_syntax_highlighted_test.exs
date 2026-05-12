defmodule AshUI.DSL.CodeBlockSyntaxHighlightedTest do
  @moduledoc """
  Tests for the code_block_syntax_highlighted widget admission in DSL storage,
  IUR adapter mapping, and HEEx rendering via both renderers.
  """

  use ExUnit.Case, async: true

  alias AshUI.DSL.Storage
  alias AshUI.Rendering.IURAdapter
  alias AshUI.Rendering.LiveUIAdapter

  # ── Storage admission ─────────────────────────────────────────

  describe "valid_widget_type?/1" do
    test "code_block_syntax_highlighted is admitted as a valid widget type" do
      assert Storage.valid_widget_type?("code_block_syntax_highlighted") == true
    end

    test "code_block_syntax_highlighted DSL with tokens validates successfully" do
      dsl = %{
        type: "code_block_syntax_highlighted",
        props: %{
          "language" => "elixir",
          "tokens" => [
            %{"type" => "keyword", "content" => "def"},
            %{"type" => "text", "content" => " "},
            %{"type" => "function", "content" => "hello"}
          ]
        },
        children: [],
        signals: [],
        metadata: %{}
      }

      assert Storage.validate_write(dsl) == :ok
    end

    test "code_block_syntax_highlighted DSL with empty tokens validates successfully" do
      dsl = %{
        type: "code_block_syntax_highlighted",
        props: %{"tokens" => []},
        children: [],
        signals: [],
        metadata: %{}
      }

      assert Storage.validate_write(dsl) == :ok
    end
  end

  # ── IURAdapter mapping ────────────────────────────────────────

  describe "IURAdapter.to_canonical/2 — code_block_syntax_highlighted element" do
    test "maps :code_block_syntax_highlighted atom to string in canonical IUR" do
      alias AshUI.Compilation.IUR

      ash_iur =
        struct(IUR,
          id: "screen-1",
          type: :screen,
          name: "test_screen",
          attributes: %{"layout" => :column},
          children: [
            struct(IUR,
              id: "code-1",
              type: :code_block_syntax_highlighted,
              name: "code_block",
              props: %{
                "language" => "elixir",
                "tokens" => [%{"type" => "keyword", "content" => "def"}]
              },
              attributes: %{},
              children: [],
              bindings: [],
              metadata: %{},
              version: 1
            )
          ],
          bindings: [],
          metadata: %{},
          version: 1
        )

      assert {:ok, canonical} = IURAdapter.to_canonical(ash_iur, telemetry: false)
      [child] = canonical["children"]
      assert child["type"] == "code_block_syntax_highlighted"
    end
  end

  # ── LiveUIAdapter rendering ───────────────────────────────────

  describe "LiveUIAdapter — code_block_syntax_highlighted rendering" do
    defp code_iur(props) do
      %{
        "type" => "screen",
        "id" => "screen-1",
        "name" => "test_screen",
        "layout" => "column",
        "children" => [
          %{
            "type" => "code_block_syntax_highlighted",
            "id" => "code-1",
            "props" => props,
            "children" => [],
            "metadata" => %{}
          }
        ],
        "bindings" => [],
        "metadata" => %{}
      }
    end

    test "renders pre/code wrapper with base class" do
      assert {:ok, heex} = LiveUIAdapter.render(code_iur(%{}))

      assert heex =~ "<pre"
      assert heex =~ "ash-code-block-syntax-highlighted"
    end

    test "renders data-language attribute when language prop is provided" do
      assert {:ok, heex} = LiveUIAdapter.render(code_iur(%{"language" => "elixir"}))

      assert heex =~ ~s(data-language="elixir")
    end

    test "omits data-language when language is not provided" do
      assert {:ok, heex} = LiveUIAdapter.render(code_iur(%{}))

      refute heex =~ "data-language"
    end

    test "renders each token as a span with correct data-token attribute" do
      tokens = [
        %{"type" => "keyword", "content" => "def"},
        %{"type" => "function", "content" => "foo"},
        %{"type" => "comment", "content" => "# note"}
      ]

      assert {:ok, heex} = LiveUIAdapter.render(code_iur(%{"tokens" => tokens}))

      assert heex =~ ~s(data-token="keyword")
      assert heex =~ "def"
      assert heex =~ ~s(data-token="function")
      assert heex =~ "foo"
      assert heex =~ ~s(data-token="comment")
      assert heex =~ "# note"
    end

    test "renders empty code block when tokens list is empty" do
      assert {:ok, heex} = LiveUIAdapter.render(code_iur(%{"tokens" => []}))

      assert heex =~ "<pre"
      assert heex =~ "<code>"
      refute heex =~ "data-token"
    end

    test "HTML-escapes token content to prevent XSS" do
      tokens = [%{"type" => "text", "content" => "<script>alert('xss')</script>"}]

      assert {:ok, heex} = LiveUIAdapter.render(code_iur(%{"tokens" => tokens}))

      refute heex =~ "<script>"
      assert heex =~ "&lt;script&gt;"
    end

    test "HTML-escapes & in token content" do
      tokens = [%{"type" => "text", "content" => "cats & dogs"}]

      assert {:ok, heex} = LiveUIAdapter.render(code_iur(%{"tokens" => tokens}))

      assert heex =~ "cats &amp; dogs"
    end
  end

  # ── LiveUI.Renderer (fallback renderer) ──────────────────────

  describe "LiveUI.Renderer — code_block_syntax_highlighted rendering" do
    defp renderer_code_iur(props) do
      %{
        "type" => "code_block_syntax_highlighted",
        "id" => "code-1",
        "props" => props,
        "children" => [],
        "metadata" => %{}
      }
    end

    test "renders pre with base class" do
      assert {:ok, heex} = LiveUI.Renderer.render(renderer_code_iur(%{}))

      assert heex =~ "ash-code-block-syntax-highlighted"
      assert heex =~ "<pre"
    end

    test "renders keyword token span" do
      tokens = [%{"type" => "keyword", "content" => "def"}]

      assert {:ok, heex} =
               LiveUI.Renderer.render(renderer_code_iur(%{"tokens" => tokens}))

      assert heex =~ ~s(data-token="keyword")
      assert heex =~ "def"
    end

    test "HTML-escapes content in renderer" do
      tokens = [%{"type" => "text", "content" => "cats & dogs"}]

      assert {:ok, heex} =
               LiveUI.Renderer.render(renderer_code_iur(%{"tokens" => tokens}))

      assert heex =~ "cats &amp; dogs"
    end

    test "renders data-language when provided" do
      assert {:ok, heex} =
               LiveUI.Renderer.render(renderer_code_iur(%{"language" => "ruby"}))

      assert heex =~ ~s(data-language="ruby")
    end

    test "empty tokens renders without span children" do
      assert {:ok, heex} =
               LiveUI.Renderer.render(renderer_code_iur(%{"tokens" => []}))

      assert heex =~ "<code>"
      refute heex =~ "data-token"
    end
  end
end
