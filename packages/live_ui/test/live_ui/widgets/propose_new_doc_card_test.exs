defmodule LiveUi.Widgets.ProposeNewDocCardTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias LiveUi.Component
  alias UnifiedIUR.Widgets.Components

  describe "propose_new_doc_card widget metadata" do
    test "registers as a layer_shell_and_callout widget with decision events" do
      metadata = Component.metadata(LiveUi.Widgets.ProposeNewDocCard)

      assert metadata.mountable?
      assert metadata.component_module == LiveUi.Widgets.ProposeNewDocCard.Component
      assert metadata.family == :layer_shell_and_callout
      assert metadata.name == :propose_new_doc_card
      assert :accept in metadata.events
      assert :reject in metadata.events
      assert :preview in metadata.events
    end

    test "is present in layer_shell_and_callout aggregation" do
      assert LiveUi.Widgets.ProposeNewDocCard in LiveUi.Widgets.LayerShellAndCallout.modules()

      assert LiveUi.Widgets.ProposeNewDocCard in LiveUi.Widgets.layer_shell_and_callout_modules()
    end
  end

  describe "propose_new_doc_card component rendering" do
    test "renders canonical root hooks, header, target path, and status badge" do
      html = render_component(&LiveUi.Widgets.ProposeNewDocCard.component/1, base_assigns())

      assert html =~ ~s(data-live-ui-widget="propose-new-doc-card")
      assert html =~ ~s(data-status="pending")
      assert html =~ ~s(aria-label="Proposed document Project brief, Pending")
      assert html =~ "Project brief"
      assert html =~ "@pascal"
      assert html =~ "docs/project-brief.md"
      assert html =~ "font-mono"
      assert html =~ "live-ui-propose-new-doc-card__header"
      assert html =~ ~s(role="status")
    end

    test "renders pending decision actions with descriptive aria labels" do
      html = render_component(&LiveUi.Widgets.ProposeNewDocCard.component/1, base_assigns())

      assert html =~ ~s(aria-label="Accept proposed document Project brief")
      assert html =~ ~s(aria-label="Reject proposed document Project brief")
      assert html =~ ~s(aria-label="Preview proposed document Project brief")
      assert html =~ ~s(phx-click="accept")
      assert html =~ ~s(phx-click="reject")
      assert html =~ ~s(phx-click="preview")
    end

    test "renders status variants and locks resolved proposals" do
      for status <- [:accepted, :rejected, :archived] do
        html =
          render_component(
            &LiveUi.Widgets.ProposeNewDocCard.component/1,
            base_assigns(%{id: "proposal-#{status}", status: status})
          )

        assert html =~ ~s(data-status="#{status}")
        assert html =~ "live-ui-propose-new-doc-card--#{status}"
        assert html =~ "live-ui-propose-new-doc-card__locked-message"
        refute html =~ "live-ui-propose-new-doc-card__accept"
        refute html =~ "live-ui-propose-new-doc-card__reject"
        assert html =~ "live-ui-propose-new-doc-card__preview"
      end
    end

    test "uses aria-controls for body expansion and conversation seed disclosure" do
      html =
        render_component(
          &LiveUi.Widgets.ProposeNewDocCard.component/1,
          base_assigns(%{
            id: "proposal-expanded",
            expanded?: true,
            seed_expanded?: true
          })
        )

      assert html =~ ~s(aria-expanded="true")
      assert html =~ ~s(aria-controls="proposal-expanded-body")
      assert html =~ ~s(aria-controls="proposal-expanded-conversation-seed")
      assert html =~ "Full draft body"
      assert html =~ "Conversation seed"
      assert html =~ "Operator asked for a project brief."
    end
  end

  describe "renderer dispatch" do
    test "propose_new_doc_card kind is in supported_kinds" do
      assert :propose_new_doc_card in LiveUi.Renderer.supported_kinds()
    end

    test "renders through native renderer with canonical action attrs" do
      element =
        Components.propose_new_doc_card(
          id: "proposal-renderer",
          target_path: "docs/project-brief.md",
          title: "Project brief",
          body_md_preview: "Draft preview.",
          status: :pending
        )

      html =
        render_component(&LiveUi.Renderer.render/1, %{
          element: element,
          event_target: "#runtime-host"
        })

      assert html =~ ~s(data-live-ui-widget="propose-new-doc-card")
      assert html =~ ~s(phx-click="canonical_interaction")
      assert html =~ ~s(phx-target="#runtime-host")
      assert html =~ ~s(phx-value-widget="propose_new_doc_card")
      assert html =~ ~s(phx-value-element_id="proposal-renderer")
      assert html =~ ~s(phx-value-action="accept")
      assert html =~ ~s(phx-value-action="reject")
      assert html =~ ~s(phx-value-action="preview")
      refute html =~ ~s(data-live-ui-component-kind="propose_new_doc_card")
      refute html =~ ~s(data-live-ui-unsupported-native-component)
    end
  end

  defp base_assigns(overrides \\ %{}) do
    Map.merge(
      %{
        id: "proposal-card",
        target_path: "docs/project-brief.md",
        title: "Project brief",
        body_md_preview: "Draft preview.",
        body_md: "Draft preview.\n\nFull draft body.",
        conversation_seed_md: "Operator asked for a project brief.",
        actor_handle: "@pascal",
        proposed_at: "2026-05-27T10:00:00Z",
        status: :pending
      },
      overrides
    )
  end
end
