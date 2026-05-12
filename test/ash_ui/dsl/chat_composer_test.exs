defmodule AshUI.DSL.ChatComposerTest do
  @moduledoc """
  Tests for the chat_composer widget admission in DSL storage,
  IUR adapter mapping, and HEEx rendering via both renderers.
  """

  use ExUnit.Case, async: true

  alias AshUI.DSL.Storage
  alias AshUI.Rendering.IURAdapter
  alias AshUI.Rendering.LiveUIAdapter

  # ── Storage admission ─────────────────────────────────────────

  describe "valid_widget_type?/1" do
    test "chat_composer is admitted as a valid widget type" do
      assert Storage.valid_widget_type?("chat_composer") == true
    end

    test "chat_composer DSL with default props validates successfully" do
      dsl = %{
        type: "chat_composer",
        props: %{
          "name" => "message",
          "value" => "",
          "placeholder" => "Type a message",
          "rows" => 3,
          "disabled" => false,
          "send_event" => "send_message",
          "change_event" => "change_message"
        },
        children: [],
        signals: [],
        metadata: %{}
      }

      assert Storage.validate_write(dsl) == :ok
    end

    test "chat_composer DSL with empty props validates successfully" do
      dsl = %{
        type: "chat_composer",
        props: %{},
        children: [],
        signals: [],
        metadata: %{}
      }

      assert Storage.validate_write(dsl) == :ok
    end
  end

  # ── IURAdapter mapping ────────────────────────────────────────

  describe "IURAdapter.to_canonical/2 — chat_composer element" do
    test "maps :chat_composer atom to string in canonical IUR" do
      alias AshUI.Compilation.IUR

      ash_iur =
        struct(IUR,
          id: "screen-1",
          type: :screen,
          name: "test_screen",
          attributes: %{"layout" => :column},
          children: [
            struct(IUR,
              id: "composer-1",
              type: :chat_composer,
              name: "chat_composer",
              props: %{
                "name" => "message",
                "send_event" => "send_message"
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
      assert child["type"] == "chat_composer"
    end
  end

  # ── LiveUIAdapter rendering ───────────────────────────────────

  describe "LiveUIAdapter — chat_composer rendering" do
    defp composer_iur(props) do
      %{
        "type" => "screen",
        "id" => "screen-1",
        "name" => "test_screen",
        "layout" => "column",
        "children" => [
          %{
            "type" => "chat_composer",
            "id" => "composer-1",
            "props" => props,
            "children" => [],
            "metadata" => %{}
          }
        ],
        "bindings" => [],
        "metadata" => %{}
      }
    end

    test "renders container with base class" do
      assert {:ok, heex} = LiveUIAdapter.render(composer_iur(%{}))

      assert heex =~ "ash-chat-composer"
    end

    test "renders form element with phx-change event" do
      assert {:ok, heex} = LiveUIAdapter.render(composer_iur(%{"change_event" => "update_draft"}))

      assert heex =~ "ash-chat-composer-form"
      assert heex =~ ~s(phx-change="update_draft")
    end

    test "renders textarea with name prop" do
      assert {:ok, heex} = LiveUIAdapter.render(composer_iur(%{"name" => "chat_input"}))

      assert heex =~ ~s(name="chat_input")
    end

    test "renders textarea with placeholder prop" do
      assert {:ok, heex} = LiveUIAdapter.render(composer_iur(%{"placeholder" => "Write here..."}))

      assert heex =~ ~s(placeholder="Write here...")
    end

    test "renders send button with send_event" do
      assert {:ok, heex} =
               LiveUIAdapter.render(composer_iur(%{"send_event" => "submit_chat"}))

      assert heex =~ "Send"
      assert heex =~ ~s(phx-click="submit_chat")
    end

    test "renders disabled attribute when disabled is true" do
      assert {:ok, heex} = LiveUIAdapter.render(composer_iur(%{"disabled" => true}))

      assert heex =~ "disabled"
    end

    test "omits disabled attribute when disabled is false" do
      assert {:ok, heex} = LiveUIAdapter.render(composer_iur(%{"disabled" => false}))

      refute heex =~ " disabled"
    end
  end

  # ── LiveUI.Renderer (fallback renderer) ──────────────────────

  describe "LiveUI.Renderer — chat_composer rendering" do
    defp renderer_composer_iur(props) do
      %{
        "type" => "chat_composer",
        "id" => "composer-1",
        "props" => props,
        "children" => [],
        "metadata" => %{}
      }
    end

    test "renders container with base class" do
      assert {:ok, heex} = LiveUI.Renderer.render(renderer_composer_iur(%{}))

      assert heex =~ "ash-chat-composer"
    end

    test "renders textarea with default name" do
      assert {:ok, heex} = LiveUI.Renderer.render(renderer_composer_iur(%{}))

      assert heex =~ ~s(name="message")
    end

    test "renders send button" do
      assert {:ok, heex} = LiveUI.Renderer.render(renderer_composer_iur(%{}))

      assert heex =~ "Send"
      assert heex =~ "ash-chat-composer-send-btn"
    end

    test "renders tool row structure" do
      assert {:ok, heex} = LiveUI.Renderer.render(renderer_composer_iur(%{}))

      assert heex =~ "ash-chat-composer-tool-row"
    end
  end
end
