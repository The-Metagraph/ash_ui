defmodule AshUI.Rendering.LiveUIAdapterTest do
  use ExUnit.Case, async: true

  alias AshUI.Compilation.IUR
  alias AshUI.Rendering.LiveUIAdapter

  describe "Section 7.2.1 - LiveUI Renderer Adapter" do
    test "render/2 returns HEEx for screen IUR" do
      canonical_iur = %{
        "type" => "screen",
        "id" => "screen-1",
        "name" => "test_screen",
        "layout" => "column",
        "children" => [
          %{
            "type" => "text",
            "id" => "text-1",
            "props" => %{"content" => "Hello"},
            "children" => [],
            "metadata" => %{}
          }
        ],
        "bindings" => [],
        "metadata" => %{}
      }

      assert {:ok, heex} = LiveUIAdapter.render(canonical_iur)
      assert is_binary(heex)
      assert String.contains?(heex, "ash-screen")
      assert String.contains?(heex, "test_screen")
    end

    test "render/2 accepts options" do
      canonical_iur = %{
        "type" => "screen",
        "id" => "screen-1",
        "name" => "test_screen",
        "layout" => "column",
        "children" => [],
        "bindings" => [],
        "metadata" => %{}
      }

      assert {:ok, heex} = LiveUIAdapter.render(canonical_iur, optimize_patches: false)
      assert is_binary(heex)
      assert String.contains?(heex, "ash-screen")
    end

    test "available?/0 returns boolean" do
      result = LiveUIAdapter.available?()
      assert is_boolean(result)
    end

    test "render_ash_iur/2 converts and renders Ash IUR" do
      ash_iur =
        struct(IUR,
          id: "test-id",
          type: :screen,
          name: "test_screen",
          attributes: %{"layout" => :row},
          children: [],
          bindings: [],
          metadata: %{},
          version: 1
        )

      assert {:ok, heex} = LiveUIAdapter.render_ash_iur(ash_iur)
      assert is_binary(heex)
      assert String.contains?(heex, "ash-screen")
    end
  end

  describe "Section 7.2.2 - LiveUI-specific Features" do
    setup do
      {:ok,
       canonical_iur: %{
         "type" => "screen",
         "id" => "screen-1",
         "name" => "test_screen",
         "layout" => "column",
         "children" => [
           %{
             "type" => "button",
             "id" => "button-1",
             "props" => %{"label" => "Click Me"},
             "children" => [],
             "metadata" => %{}
           },
           %{
             "type" => "input",
             "id" => "input-1",
             "props" => %{"name" => "username"},
             "children" => [],
             "metadata" => %{}
           }
         ],
         "bindings" => [
           %{
             "id" => "binding-1",
             "type" => "bidirectional",
             "target" => "username",
             "source" => %{"resource" => "User", "field" => "name"},
             "element_id" => "input-1",
             "metadata" => %{}
           }
         ],
         "metadata" => %{}
       }}
    end

    test "configure_event_bindings/2 extracts action events", %{canonical_iur: iur} do
      config = LiveUIAdapter.configure_event_bindings(iur, event_prefix: "ash")

      assert is_list(config.events)
      assert config.event_prefix == "ash"

      action_events =
        Enum.filter(config.events, fn e ->
          String.contains?(e.event, "action")
        end)

      assert length(action_events) > 0
    end

    test "configure_event_bindings/2 extracts change events", %{canonical_iur: iur} do
      config = LiveUIAdapter.configure_event_bindings(iur)

      change_events =
        Enum.filter(config.events, fn e ->
          String.contains?(e.event, "change")
        end)

      assert length(change_events) > 0
    end

    test "configure_hooks/2 returns default hooks", %{canonical_iur: iur} do
      hooks = LiveUIAdapter.configure_hooks(iur)

      assert is_list(hooks)

      lifecycle_hook = Enum.find(hooks, fn h -> h.name == :ash_ui_lifecycle end)
      assert lifecycle_hook != nil
      assert lifecycle_hook.on_mount == {AshUI.LiveView.Hooks, :on_mount_ash_ui}
    end

    test "configure_hooks/2 includes patch hooks when optimize_patches is true", %{
      canonical_iur: iur
    } do
      hooks = LiveUIAdapter.configure_hooks(iur, optimize_patches: true)

      patch_hook = Enum.find(hooks, fn h -> h.name == :ash_ui_patches end)
      assert patch_hook != nil
    end

    test "configure_hooks/2 excludes patch hooks when optimize_patches is false", %{
      canonical_iur: iur
    } do
      hooks = LiveUIAdapter.configure_hooks(iur, optimize_patches: false)

      patch_hook = Enum.find(hooks, fn h -> h.name == :ash_ui_patches end)
      assert patch_hook == nil
    end

    test "configure_assigns/2 extracts binding assigns", %{canonical_iur: iur} do
      assigns = LiveUIAdapter.configure_assigns(iur)

      assert is_map(assigns)
      assert Map.has_key?(assigns, "username")
    end

    test "configure_assigns/2 merges initial assigns", %{canonical_iur: iur} do
      assigns = LiveUIAdapter.configure_assigns(iur, assigns: %{custom: "value"})

      assert assigns.custom == "value"
      assert Map.has_key?(assigns, "username")
    end

    test "configure_patch_optimization/2 returns optimization config", %{canonical_iur: iur} do
      config = LiveUIAdapter.configure_patch_optimization(iur)

      assert config.enabled == true
      assert is_list(config.static_ids)
      assert is_list(config.dynamic_streams)
    end

    test "configure_patch_optimization/2 respects optimize_patches option", %{canonical_iur: iur} do
      config = LiveUIAdapter.configure_patch_optimization(iur, optimize_patches: false)

      assert config.enabled == false
    end
  end

  describe "Section 7.2.2 - HEEx Generation" do
    test "generates button with phx-click attribute" do
      iur = %{
        "type" => "button",
        "id" => "btn-1",
        "props" => %{"label" => "Submit"},
        "children" => [],
        "metadata" => %{},
        "bindings" => [
          %{
            "id" => "save_profile",
            "type" => "event",
            "target" => "submit",
            "element_id" => "btn-1",
            "metadata" => %{"owner_signal" => "click"}
          }
        ]
      }

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert String.contains?(heex, "phx-click=\"ash_ui_action\"")
      assert String.contains?(heex, "phx-value-element_id=\"btn-1\"")
      assert String.contains?(heex, "phx-value-signal=\"click\"")
      assert String.contains?(heex, "Submit")
    end

    test "generates input with phx-blur and phx-change attributes" do
      iur = %{
        "type" => "input",
        "id" => "input-1",
        "props" => %{"name" => "email"},
        "children" => [],
        "metadata" => %{}
      }

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert String.contains?(heex, "phx-blur=\"ash_ui_change\"")
      assert String.contains?(heex, "phx-change=\"ash_ui_change\"")
      assert String.contains?(heex, "phx-value-element_id=\"input-1\"")
      assert String.contains?(heex, "phx-value-signal=\"change\"")
      assert String.contains?(heex, "name=\"email\"")
    end

    test "generates checkbox with phx-click attribute" do
      iur = %{
        "type" => "checkbox",
        "id" => "check-1",
        "props" => %{"name" => "agree"},
        "children" => [],
        "metadata" => %{}
      }

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert String.contains?(heex, "type=\"checkbox\"")
      assert String.contains?(heex, "phx-click")
    end

    test "generates select with options" do
      iur = %{
        "type" => "select",
        "id" => "select-1",
        "props" => %{"name" => "country", "options" => ["USA", "Canada", "Mexico"]},
        "children" => [],
        "metadata" => %{}
      }

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert String.contains?(heex, "<select")
      assert String.contains?(heex, "USA")
      assert String.contains?(heex, "Canada")
      assert String.contains?(heex, "Mexico")
    end

    test "generates row with gap style" do
      iur = %{
        "type" => "row",
        "id" => "row-1",
        "props" => %{"spacing" => 16},
        "children" => [],
        "metadata" => %{}
      }

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert String.contains?(heex, "ash-row")
      assert String.contains?(heex, "gap: 16px")
    end

    test "generates column with gap style" do
      iur = %{
        "type" => "column",
        "id" => "col-1",
        "props" => %{"spacing" => 24},
        "children" => [],
        "metadata" => %{}
      }

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert String.contains?(heex, "ash-column")
      assert String.contains?(heex, "gap: 24px")
    end

    test "generates text with font size and color" do
      iur = %{
        "type" => "text",
        "id" => "text-1",
        "props" => %{"content" => "Hello World", "size" => 18, "color" => "blue"},
        "children" => [],
        "metadata" => %{}
      }

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert String.contains?(heex, "Hello World")
      assert String.contains?(heex, "font-size: 18px")
      assert String.contains?(heex, "color: blue")
    end

    test "generates dedicated navigation markup for example-facing custom surfaces" do
      Enum.each(
        [
          {
            "custom:menu",
            "ash-menu",
            "ash-menu-nav",
            "Menu focus stays on nested public buttons."
          },
          {
            "custom:tabs",
            "ash-tabs",
            "ash-tabs-panels",
            "Panels stay inside the custom tabs shell."
          },
          {
            "custom:command_palette",
            "ash-command-palette",
            "ash-command-palette-results",
            "Commands execute through nested public buttons."
          }
        ],
        fn {type, wrapper_class, section_class, detail_copy} ->
          iur = %{
            "type" => type,
            "id" => "#{type}-demo",
            "props" => %{
              "title" => "#{type} Demo",
              "description" => detail_copy
            },
            "children" => [
              %{
                "type" => "button",
                "id" => "#{type}-nav",
                "props" => %{"label" => "Overview"},
                "children" => [],
                "metadata" => %{
                  "slot" => if(type == "custom:command_palette", do: "search", else: "nav")
                }
              },
              %{
                "type" => "text",
                "id" => "#{type}-body",
                "props" => %{"content" => detail_copy},
                "children" => [],
                "metadata" => %{"slot" => "body"}
              }
            ],
            "metadata" => %{}
          }

          {:ok, heex} = LiveUIAdapter.render(iur, force_fallback: true)

          assert heex =~ wrapper_class
          assert heex =~ section_class
          assert heex =~ detail_copy
          assert heex =~ "Overview"
        end
      )
    end

    test "generates dedicated display markup for example-facing custom surfaces" do
      Enum.each(
        [
          {"custom:viewport", "ash-viewport", "ash-viewport-body", "body"},
          {"custom:scroll_bar", "ash-scroll-bar", "ash-scroll-bar-track", "body"},
          {"custom:split_pane", "ash-split-pane", "ash-split-pane-secondary", "secondary"},
          {"custom:canvas", "ash-canvas-surface", "ash-canvas-toolbar", "toolbar"}
        ],
        fn {type, wrapper_class, section_class, slot} ->
          children =
            case type do
              "custom:split_pane" ->
                [
                  %{
                    "type" => "text",
                    "id" => "#{type}-primary",
                    "props" => %{"content" => "Primary lane"},
                    "children" => [],
                    "metadata" => %{"slot" => "primary"}
                  },
                  %{
                    "type" => "text",
                    "id" => "#{type}-secondary",
                    "props" => %{"content" => "Secondary lane"},
                    "children" => [],
                    "metadata" => %{"slot" => "secondary"}
                  }
                ]

              "custom:canvas" ->
                [
                  %{
                    "type" => "button",
                    "id" => "#{type}-tool",
                    "props" => %{"label" => "Ink"},
                    "children" => [],
                    "metadata" => %{"slot" => "toolbar"}
                  },
                  %{
                    "type" => "text",
                    "id" => "#{type}-body",
                    "props" => %{"content" => "Annotation layer"},
                    "children" => [],
                    "metadata" => %{"slot" => "body"}
                  }
                ]

              _other ->
                [
                  %{
                    "type" => "text",
                    "id" => "#{type}-body",
                    "props" => %{"content" => "Viewport detail"},
                    "children" => [],
                    "metadata" => %{"slot" => slot}
                  }
                ]
            end

          iur = %{
            "type" => type,
            "id" => "#{type}-demo",
            "props" => %{"title" => "#{type} Demo", "description" => "Dedicated example shell"},
            "children" => children,
            "metadata" => %{}
          }

          {:ok, heex} = LiveUIAdapter.render(iur, force_fallback: true)

          assert heex =~ wrapper_class
          assert heex =~ section_class
          assert heex =~ "Dedicated example shell"
        end
      )
    end

    test "generates dedicated layered markup for example-facing overlay surfaces" do
      Enum.each(
        [
          {"custom:overlay", "ash-overlay-surface", "ash-overlay-actions", "actions"},
          {"custom:dialog", "ash-dialog-surface", "ash-dialog-actions", "actions"},
          {
            "custom:alert_dialog",
            "ash-alert-dialog-surface",
            "ash-alert-dialog-actions",
            "actions"
          },
          {"custom:context_menu", "ash-context-menu", "ash-context-menu-items", "menu"},
          {"custom:toast", "ash-toast", "ash-toast-actions", "actions"}
        ],
        fn {type, wrapper_class, section_class, slot} ->
          children =
            case type do
              "custom:context_menu" ->
                [
                  %{
                    "type" => "button",
                    "id" => "#{type}-item",
                    "props" => %{"label" => "Inspect"},
                    "children" => [],
                    "metadata" => %{"slot" => "menu"}
                  },
                  %{
                    "type" => "text",
                    "id" => "#{type}-body",
                    "props" => %{"content" => "Selected operation"},
                    "children" => [],
                    "metadata" => %{"slot" => "body"}
                  }
                ]

              _other ->
                [
                  %{
                    "type" => "text",
                    "id" => "#{type}-body",
                    "props" => %{"content" => "Layered detail"},
                    "children" => [],
                    "metadata" => %{"slot" => "body"}
                  },
                  %{
                    "type" => "button",
                    "id" => "#{type}-action",
                    "props" => %{"label" => "Acknowledge"},
                    "children" => [],
                    "metadata" => %{"slot" => slot}
                  }
                ]
            end

          iur = %{
            "type" => type,
            "id" => "#{type}-demo",
            "props" => %{
              "title" => "#{type} Demo",
              "description" => "Layered example shell",
              if(type == "custom:toast", do: "visible", else: "open") => true
            },
            "children" => children,
            "metadata" => %{}
          }

          {:ok, heex} = LiveUIAdapter.render(iur, force_fallback: true)

          assert heex =~ wrapper_class
          assert heex =~ section_class
          assert heex =~ "Layered example shell"

          if type == "custom:context_menu" do
            assert heex =~ "Inspect"
          else
            assert heex =~ "Acknowledge"
          end
        end
      )
    end

    test "generates dedicated data-surface markup for advanced collection and document examples" do
      Enum.each(
        [
          {"list", "ash-list", "ash-list-items", "Urgent approvals"},
          {"table", "ash-table-surface", "ash-table-wrapper", "API gateway"},
          {"custom:tree_view", "ash-tree-view", "ash-tree-view-list", "Runtime graph"},
          {
            "custom:markdown_viewer",
            "ash-markdown-viewer",
            "ash-markdown-viewer-body",
            "Incident Guide"
          },
          {
            "custom:log_viewer",
            "ash-log-viewer",
            "ash-log-viewer-lines",
            "Ash UI screen mounted with 5 element bindings."
          }
        ],
        fn {type, wrapper_class, section_class, expected_copy} ->
          props =
            case type do
              "list" ->
                %{
                  "title" => "Queue",
                  "description" => "Collection view",
                  "items" => [
                    %{
                      "title" => "Urgent approvals",
                      "summary" => "4 records",
                      "meta" => "SLA 15m"
                    }
                  ]
                }

              "table" ->
                %{
                  "title" => "Table",
                  "description" => "Tabular collection",
                  "columns" => [
                    %{"key" => "service", "label" => "Service"},
                    %{"key" => "status", "label" => "Status"}
                  ],
                  "items" => [%{"service" => "API gateway", "status" => "Ready"}]
                }

              "custom:tree_view" ->
                %{
                  "title" => "Tree",
                  "description" => "Hierarchy",
                  "model" => [
                    %{
                      "label" => "Runtime graph",
                      "meta" => "Primary",
                      "children" => [%{"label" => "Binding runtime", "meta" => "Healthy"}]
                    }
                  ]
                }

              "custom:markdown_viewer" ->
                %{
                  "title" => "Markdown",
                  "description" => "Document surface",
                  "content" => "# Incident Guide\n\n- Confirm scope"
                }

              "custom:log_viewer" ->
                %{
                  "title" => "Logs",
                  "description" => "Stream view",
                  "entries" => [
                    %{
                      "timestamp" => "12:04:19",
                      "level" => "INFO",
                      "message" => "Ash UI screen mounted with 5 element bindings."
                    }
                  ]
                }
            end

          iur = %{
            "type" => type,
            "id" => "#{type}-demo",
            "props" => props,
            "children" => [
              %{
                "type" => "button",
                "id" => "#{type}-action",
                "props" => %{"label" => "Refresh"},
                "children" => [],
                "metadata" => %{"slot" => "actions"}
              },
              %{
                "type" => "text",
                "id" => "#{type}-footer",
                "props" => %{"content" => "Bound runtime state"},
                "children" => [],
                "metadata" => %{"slot" => "footer"}
              }
            ],
            "metadata" => %{}
          }

          {:ok, heex} = LiveUIAdapter.render(iur, force_fallback: true)

          assert heex =~ wrapper_class
          assert heex =~ section_class
          assert heex =~ expected_copy
          assert heex =~ "Refresh"
          assert heex =~ "Bound runtime state"
        end
      )
    end

    test "generates dedicated feedback and chart markup for advanced signal examples" do
      Enum.each(
        [
          {"custom:status", "ash-status-surface", "ash-status-pill", "Healthy"},
          {"custom:progress", "ash-progress-surface", "ash-progress-track", "42%"},
          {"custom:gauge", "ash-gauge-surface", "ash-gauge-meter", "63%"},
          {
            "custom:inline_feedback",
            "ash-inline-feedback",
            "ash-inline-feedback-badge",
            "Rollback ready"
          },
          {"custom:sparkline", "ash-sparkline-surface", "ash-sparkline-chart", "00m"},
          {"custom:bar_chart", "ash-bar-chart", "ash-bar-chart-bars", "us-east"},
          {"custom:line_chart", "ash-line-chart", "ash-line-chart-grid", "Mon"}
        ],
        fn {type, wrapper_class, section_class, expected_copy} ->
          props =
            case type do
              "custom:status" ->
                %{
                  "title" => "Status",
                  "description" => "Signal surface",
                  "model" => %{
                    "label" => "Healthy",
                    "tone" => "success",
                    "detail" => "All queues nominal."
                  }
                }

              "custom:progress" ->
                %{
                  "title" => "Progress",
                  "description" => "Rollout surface",
                  "model" => %{
                    "label" => "Canary",
                    "value" => 42,
                    "total" => 100,
                    "detail" => "42 percent live."
                  }
                }

              "custom:gauge" ->
                %{
                  "title" => "Gauge",
                  "description" => "Capacity surface",
                  "model" => %{
                    "label" => "CPU",
                    "value" => 63,
                    "max" => 100,
                    "detail" => "Within budget."
                  }
                }

              "custom:inline_feedback" ->
                %{
                  "title" => "Feedback",
                  "description" => "Advisory",
                  "model" => %{
                    "tone" => "success",
                    "title" => "Rollback ready",
                    "detail" => "Recovery checklist is prepared."
                  }
                }

              "custom:sparkline" ->
                %{
                  "title" => "Sparkline",
                  "description" => "Trend",
                  "series" => [
                    %{"label" => "00m", "value" => 18},
                    %{"label" => "05m", "value" => 22}
                  ]
                }

              "custom:bar_chart" ->
                %{
                  "title" => "Bars",
                  "description" => "Comparison",
                  "series" => [
                    %{"label" => "us-east", "value" => 84},
                    %{"label" => "us-west", "value" => 63}
                  ]
                }

              "custom:line_chart" ->
                %{
                  "title" => "Trend line",
                  "description" => "Trend",
                  "series" => [
                    %{"label" => "Mon", "value" => 7},
                    %{"label" => "Tue", "value" => 9}
                  ]
                }
            end

          iur = %{
            "type" => type,
            "id" => "#{type}-demo",
            "props" => props,
            "children" => [
              %{
                "type" => "button",
                "id" => "#{type}-action",
                "props" => %{"label" => "Switch"},
                "children" => [],
                "metadata" => %{"slot" => "actions"}
              },
              %{
                "type" => "text",
                "id" => "#{type}-footer",
                "props" => %{"content" => "Metric bound from runtime"},
                "children" => [],
                "metadata" => %{"slot" => "footer"}
              }
            ],
            "metadata" => %{}
          }

          {:ok, heex} = LiveUIAdapter.render(iur, force_fallback: true)

          assert heex =~ wrapper_class
          assert heex =~ section_class
          assert heex =~ expected_copy
          assert heex =~ "Switch"
          assert heex =~ "Metric bound from runtime"
        end
      )
    end

    test "generates dedicated operational markup for advanced monitoring examples" do
      Enum.each(
        [
          {"custom:stream_widget", "ash-stream-widget", "ash-stream-widget-entries", "ingest"},
          {
            "custom:process_monitor",
            "ash-process-monitor",
            "ash-process-monitor-cards",
            "scheduler"
          },
          {
            "custom:supervision_tree_viewer",
            "ash-supervision-tree-viewer",
            "ash-supervision-tree-list",
            "Worker supervisor"
          },
          {
            "custom:cluster_dashboard",
            "ash-cluster-dashboard",
            "ash-cluster-dashboard-grid",
            "Regional cluster stable"
          }
        ],
        fn {type, wrapper_class, section_class, expected_copy} ->
          props =
            case type do
              "custom:stream_widget" ->
                %{
                  "title" => "Stream",
                  "description" => "Operational feed",
                  "entries" => [
                    %{
                      "timestamp" => "13:04:12",
                      "label" => "ingest",
                      "message" => "Packet accepted."
                    }
                  ]
                }

              "custom:process_monitor" ->
                %{
                  "title" => "Process monitor",
                  "description" => "Runtime snapshot",
                  "model" => %{
                    "summary" => "Schedulers and workers are healthy.",
                    "processes" => [
                      %{"name" => "scheduler", "state" => "running", "meta" => "0 restarts"}
                    ]
                  }
                }

              "custom:supervision_tree_viewer" ->
                %{
                  "title" => "Supervision tree",
                  "description" => "Hierarchy",
                  "model" => %{
                    "label" => "Worker supervisor",
                    "meta" => "Primary",
                    "nodes" => [%{"label" => "queue_worker", "meta" => "running"}]
                  }
                }

              "custom:cluster_dashboard" ->
                %{
                  "title" => "Cluster dashboard",
                  "description" => "Regional overview",
                  "model" => %{
                    "headline" => "Regional cluster stable",
                    "detail" => "All regions are inside budget.",
                    "regions" => [%{"label" => "us-east", "status" => "Healthy", "load" => "63%"}],
                    "alerts" => [%{"title" => "Billing lag", "message" => "Watching retries."}]
                  }
                }
            end

          iur = %{
            "type" => type,
            "id" => "#{type}-demo",
            "props" => props,
            "children" => [
              %{
                "type" => "button",
                "id" => "#{type}-action",
                "props" => %{"label" => "Refresh"},
                "children" => [],
                "metadata" => %{"slot" => "actions"}
              },
              %{
                "type" => "text",
                "id" => "#{type}-footer",
                "props" => %{"content" => "Operational snapshot bound from runtime"},
                "children" => [],
                "metadata" => %{"slot" => "footer"}
              }
            ],
            "metadata" => %{}
          }

          {:ok, heex} = LiveUIAdapter.render(iur, force_fallback: true)

          assert heex =~ wrapper_class
          assert heex =~ section_class
          assert heex =~ expected_copy
          assert heex =~ "Refresh"
          assert heex =~ "Operational snapshot bound from runtime"
        end
      )
    end
  end

  describe "Section 7.2.1 - Event Binding Configuration" do
    test "build_event_handlers creates handler maps" do
      iur = %{
        "type" => "screen",
        "id" => "screen-1",
        "name" => "test",
        "layout" => "column",
        "children" => [
          %{
            "type" => "button",
            "id" => "btn-1",
            "props" => %{},
            "children" => [],
            "metadata" => %{}
          }
        ],
        "bindings" => [],
        "metadata" => %{}
      }

      config = LiveUIAdapter.configure_event_bindings(iur)

      assert is_list(config.events)
      assert is_list(config.handlers)

      if length(config.handlers) > 0 do
        handler = hd(config.handlers)
        assert Map.has_key?(handler, :event)
        assert Map.has_key?(handler, :handler)
        assert Map.has_key?(handler, :target)
      end
    end
  end

  describe "Phase 11 semantic widget rendering" do
    test "renders authored semantic widget props into visible HEEx" do
      {:ok, heex} = LiveUIAdapter.render(semantic_screen_iur())

      assert heex =~ "ash-hero"
      assert heex =~ "Authored through UnifiedUi"
      assert heex =~ "Persisted through AshUI.Resource.Authority."
      assert heex =~ "ash-badge-pill"
      assert heex =~ "Ready"
      assert heex =~ "ash-stat"
      assert heex =~ "Persistent screen bridge"
      assert heex =~ "ash-key-value"
      assert heex =~ "Persisted route metadata"
      assert heex =~ "ash-info-list"
      assert heex =~ "semantic_widgets"
      assert heex =~ "ash-form-field"
      assert heex =~ "Display name"
      assert heex =~ "Used to verify form_field survives the persistence bridge"
      assert heex =~ "phx-change=\"ash_ui_change\""
    end
  end

  defp semantic_screen_iur do
    %{
      "type" => "screen",
      "id" => "semantic-screen",
      "name" => "semantic_screen",
      "layout" => "column",
      "children" => [
        %{
          "type" => "hero",
          "id" => "hero-panel",
          "props" => %{
            "eyebrow" => "Authoring",
            "title" => "Authored through UnifiedUi",
            "message" => "Persisted through AshUI.Resource.Authority."
          },
          "children" => [
            %{
              "type" => "badge",
              "id" => "status-badge",
              "props" => %{"presentation" => "pill", "text" => "Ready"},
              "children" => [],
              "metadata" => %{}
            }
          ],
          "metadata" => %{}
        },
        %{
          "type" => "stat",
          "id" => "runtime-stat",
          "props" => %{
            "title" => "Runtime",
            "value" => "Ash UI",
            "message" => "Persistent screen bridge"
          },
          "children" => [],
          "metadata" => %{}
        },
        %{
          "type" => "key_value",
          "id" => "route-meta",
          "props" => %{
            "label" => "Route",
            "value" => "/authored",
            "description" => "Persisted route metadata"
          },
          "children" => [],
          "metadata" => %{}
        },
        %{
          "type" => "info_list",
          "id" => "highlights",
          "props" => %{
            "items" => [
              %{"id" => "upstream_dsl", "value" => "upstream_dsl"},
              %{"id" => "semantic_widgets", "value" => "semantic_widgets"}
            ]
          },
          "children" => [],
          "metadata" => %{}
        },
        %{
          "type" => "form_builder",
          "id" => "profile-form",
          "props" => %{},
          "children" => [
            %{
              "type" => "form_field",
              "id" => "display-name-field",
              "props" => %{"name" => "display_name"},
              "children" => [
                %{
                  "type" => "label",
                  "id" => "display-name-label",
                  "props" => %{"for" => "display-name-input", "text" => "Display name"},
                  "children" => [],
                  "metadata" => %{}
                },
                %{
                  "type" => "input",
                  "id" => "display-name-input",
                  "props" => %{"name" => "display_name", "placeholder" => "Enter your name"},
                  "children" => [],
                  "metadata" => %{}
                },
                %{
                  "type" => "text",
                  "id" => "display-name-help",
                  "props" => %{
                    "content" => "Used to verify form_field survives the persistence bridge"
                  },
                  "children" => [],
                  "metadata" => %{}
                }
              ],
              "metadata" => %{}
            }
          ],
          "metadata" => %{}
        }
      ],
      "bindings" => [
        %{
          "id" => "binding-1",
          "type" => "bidirectional",
          "target" => "display_name",
          "source" => %{"resource" => "User", "field" => "name"},
          "element_id" => "display-name-input",
          "metadata" => %{}
        }
      ],
      "metadata" => %{}
    }
  end

  # Track-B widget tests bundled from PRs #79-#97.

  describe "inline_rich_text_heading widget rendering" do
    test "generates inline_rich_text_heading with mixed text and em segments" do
      iur = %{
        "type" => "inline_rich_text_heading",
        "id" => "heading-1",
        "props" => %{
          "level" => "h1",
          "segments" => [
            %{"type" => "text", "value" => "The operator surface, "},
            %{"type" => "em", "value" => "for the team that thinks in documents."}
          ]
        },
        "children" => [],
        "metadata" => %{}
      }

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert String.contains?(heex, "<h1")
      assert String.contains?(heex, "</h1>")
      assert String.contains?(heex, "ash-inline-rich-text-heading")
      assert String.contains?(heex, "ash-inline-rich-text-heading-h1")

      assert String.contains?(
               heex,
               "The operator surface, <em>for the team that thinks in documents.</em>"
             )
    end

    test "inline_rich_text_heading respects level prop for h2 through h6" do
      for level <- ~w(h2 h3 h4 h5 h6) do
        iur = %{
          "type" => "inline_rich_text_heading",
          "id" => "heading-#{level}",
          "props" => %{
            "level" => level,
            "segments" => [%{"type" => "text", "value" => "x"}]
          },
          "children" => [],
          "metadata" => %{}
        }

        {:ok, heex} = LiveUIAdapter.render(iur)
        assert String.contains?(heex, "<#{level}"), "expected <#{level}> tag for level=#{level}"
        assert String.contains?(heex, "</#{level}>")
        assert String.contains?(heex, "ash-inline-rich-text-heading-#{level}")
      end
    end

    test "inline_rich_text_heading falls back to h1 when level prop is missing or invalid" do
      iur = %{
        "type" => "inline_rich_text_heading",
        "id" => "heading-default",
        "props" => %{
          "segments" => [%{"type" => "text", "value" => "Default"}]
        },
        "children" => [],
        "metadata" => %{}
      }

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert String.contains?(heex, "<h1")
      assert String.contains?(heex, "Default")

      bogus = put_in(iur, ["props", "level"], "h99")
      {:ok, heex_bogus} = LiveUIAdapter.render(bogus)
      assert String.contains?(heex_bogus, "<h1")
    end

    test "inline_rich_text_heading accepts atom-keyed segments" do
      iur = %{
        "type" => "inline_rich_text_heading",
        "id" => "heading-atom",
        "props" => %{
          "level" => "h2",
          "segments" => [
            %{type: :text, value: "Hello "},
            %{type: :em, value: "world"}
          ]
        },
        "children" => [],
        "metadata" => %{}
      }

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert String.contains?(heex, "<h2")
      assert String.contains?(heex, "Hello <em>world</em>")
    end

    test "inline_rich_text_heading produces no literal color or font-family values" do
      iur = %{
        "type" => "inline_rich_text_heading",
        "id" => "heading-pure",
        "props" => %{
          "level" => "h1",
          "segments" => [
            %{"type" => "text", "value" => "Hello "},
            %{"type" => "em", "value" => "world"}
          ]
        },
        "children" => [],
        "metadata" => %{}
      }

      {:ok, heex} = LiveUIAdapter.render(iur)
      refute heex =~ ~r/#[0-9a-fA-F]{3,6}\b/
      refute heex =~ ~r/\brgb\s*\(/
      refute heex =~ ~r/font-family\s*:/i
    end
  end

  describe "disclosure widget rendering" do
    test "generates a disclosure closed by default with summary and body" do
      iur = %{
        "type" => "disclosure",
        "id" => "disclosure-1",
        "props" => %{"summary" => "Use a password instead"},
        "children" => [
          %{
            "type" => "text",
            "id" => "body-text",
            "props" => %{"content" => "Password form body"},
            "children" => [],
            "metadata" => %{}
          }
        ],
        "metadata" => %{}
      }

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert String.contains?(heex, "<details")
      assert String.contains?(heex, "</details>")
      assert String.contains?(heex, "ash-disclosure")
      assert String.contains?(heex, "ash-disclosure-summary")
      assert String.contains?(heex, "ash-disclosure-body")
      assert String.contains?(heex, "Use a password instead")
      assert String.contains?(heex, "Password form body")
      refute heex =~ ~r/<details[^>]*\sopen/
    end

    test "disclosure adds the open attribute when open prop is true" do
      iur = %{
        "type" => "disclosure",
        "id" => "disclosure-open",
        "props" => %{"summary" => "Reveal", "open" => true},
        "children" => [],
        "metadata" => %{}
      }

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert heex =~ ~r/<details[^>]*\sopen/
    end

    test "disclosure produces no literal color or font-family values" do
      iur = %{
        "type" => "disclosure",
        "id" => "disclosure-pure",
        "props" => %{"summary" => "Reveal", "open" => true},
        "children" => [],
        "metadata" => %{}
      }

      {:ok, heex} = LiveUIAdapter.render(iur)
      refute heex =~ ~r/#[0-9a-fA-F]{3,6}\b/
      refute heex =~ ~r/\brgb\s*\(/
      refute heex =~ ~r/font-family\s*:/i
    end
  end

  describe "phoenix_form widget rendering" do
    test "generates a phoenix_form with phx-submit/phx-change events and submit button" do
      iur = %{
        "type" => "phoenix_form",
        "id" => "form-1",
        "props" => %{
          "submit_event" => "submit",
          "change_event" => "validate",
          "submit_label" => "Send sign-in link",
          "fields" => [
            %{
              "name" => "email",
              "type" => "email",
              "label" => "Work email",
              "autocomplete" => "email",
              "required" => true
            }
          ]
        },
        "children" => [],
        "metadata" => %{}
      }

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert String.contains?(heex, "<form")
      assert String.contains?(heex, "</form>")
      assert String.contains?(heex, ~s(phx-submit="submit"))
      assert String.contains?(heex, ~s(phx-change="validate"))
      assert String.contains?(heex, "ash-phoenix-form")
      assert String.contains?(heex, "ash-phoenix-form-field")
      assert String.contains?(heex, "ash-phoenix-form-label")
      assert String.contains?(heex, "ash-phoenix-form-input")
      assert String.contains?(heex, "ash-phoenix-form-submit")
      assert String.contains?(heex, "ash-phoenix-form-submit-primary")
      assert String.contains?(heex, ~s(name="email"))
      assert String.contains?(heex, ~s(type="email"))
      assert String.contains?(heex, ~s(autocomplete="email"))
      assert String.contains?(heex, " required")
      assert String.contains?(heex, "Work email")
      assert String.contains?(heex, "Send sign-in link")
    end

    test "phoenix_form supports password strategy shape with ghost variant" do
      iur = %{
        "type" => "phoenix_form",
        "id" => "form-2",
        "props" => %{
          "submit_event" => "submit_password",
          "change_event" => "validate_password",
          "submit_label" => "Sign in with password",
          "submit_variant" => "ghost",
          "fields" => [
            %{"name" => "email", "type" => "email", "label" => "Work email"},
            %{
              "name" => "password",
              "type" => "password",
              "label" => "Password",
              "autocomplete" => "current-password"
            }
          ]
        },
        "children" => [],
        "metadata" => %{}
      }

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert String.contains?(heex, ~s(type="email"))
      assert String.contains?(heex, ~s(type="password"))
      assert String.contains?(heex, ~s(autocomplete="current-password"))
      assert String.contains?(heex, "ash-phoenix-form-submit-ghost")
      assert String.contains?(heex, "Sign in with password")
    end

    test "phoenix_form uses sensible defaults when props omitted" do
      iur = %{
        "type" => "phoenix_form",
        "id" => "form-defaults",
        "props" => %{"fields" => []},
        "children" => [],
        "metadata" => %{}
      }

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert String.contains?(heex, ~s(phx-submit="submit"))
      assert String.contains?(heex, ~s(phx-change="validate"))
      assert String.contains?(heex, ">Submit</button>")
      assert String.contains?(heex, "ash-phoenix-form-submit-primary")
    end

    test "phoenix_form produces no literal color or font-family values" do
      iur = %{
        "type" => "phoenix_form",
        "id" => "form-pure",
        "props" => %{
          "fields" => [
            %{"name" => "email", "type" => "email", "label" => "Email", "required" => true}
          ]
        },
        "children" => [],
        "metadata" => %{}
      }

      {:ok, heex} = LiveUIAdapter.render(iur)
      refute heex =~ ~r/#[0-9a-fA-F]{3,6}\b/
      refute heex =~ ~r/\brgb\s*\(/
      refute heex =~ ~r/font-family\s*:/i
    end
  end

  describe "kicker widget rendering" do
    test "renders items with separators between them" do
      iur = %{
        "type" => "kicker",
        "id" => "kicker-1",
        "props" => %{"items" => ["Operator sign-in", "Magic link"], "separator" => "·"},
        "children" => [],
        "metadata" => %{}
      }

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert heex =~ "ash-kicker"
      assert heex =~ "ash-kicker-item"
      assert heex =~ "ash-kicker-separator"
      assert heex =~ "Operator sign-in"
      assert heex =~ "Magic link"
      assert heex =~ "·"
    end

    test "single item renders without any separator" do
      iur = %{
        "type" => "kicker",
        "id" => "kicker-single",
        "props" => %{"items" => ["Solo label"], "separator" => "·"},
        "children" => [],
        "metadata" => %{}
      }

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert heex =~ "Solo label"
      assert heex =~ "ash-kicker-item"
      refute heex =~ "ash-kicker-separator"
    end

    test "custom separator string appears between items" do
      iur = %{
        "type" => "kicker",
        "id" => "kicker-pipe",
        "props" => %{"items" => ["Alpha", "Beta"], "separator" => "|"},
        "children" => [],
        "metadata" => %{}
      }

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert heex =~ "ash-kicker-separator"
      assert heex =~ "|"
    end
  end

  describe "avatar widget rendering" do
    test "renders initials with base class and data-variant" do
      iur = avatar_iur("PC", nil, "pascal", "medium", "round", nil)

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert heex =~ "ash-avatar"
      assert heex =~ "ash-avatar-medium"
      assert heex =~ ~s(data-variant="pascal")
      assert heex =~ "PC"
    end

    test "renders img element when image_src provided" do
      iur = avatar_iur(nil, "/uploads/avatar.jpg", "neutral", "medium", "round", "Matt DeCourcey")

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert heex =~ ~s(src="/uploads/avatar.jpg")
      assert heex =~ "ash-avatar-image"
    end

    test "square shape applies ash-avatar-square class" do
      iur = avatar_iur("PC", nil, "pascal", "medium", "square", nil)

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert heex =~ "ash-avatar-square"
    end

    test "round shape omits ash-avatar-square class" do
      iur = avatar_iur("PC", nil, "neutral", "medium", "round", nil)

      {:ok, heex} = LiveUIAdapter.render(iur)
      refute heex =~ "ash-avatar-square"
    end

    test "small size applies ash-avatar-small class" do
      iur = avatar_iur("PC", nil, "neutral", "small", "round", nil)

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert heex =~ "ash-avatar-small"
    end

    test "large size applies ash-avatar-large class" do
      iur = avatar_iur("PC", nil, "neutral", "large", "round", nil)

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert heex =~ "ash-avatar-large"
    end

    test "aria_label produces role=img and aria-label attributes" do
      iur = avatar_iur("PC", nil, "pascal", "medium", "round", "Pascal Charbonneau")

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert heex =~ ~s(aria-label="Pascal Charbonneau")
      assert heex =~ ~s(role="img")
    end

    test "background-color uses CSS variable with fallback" do
      iur = avatar_iur("PC", nil, "codex", "medium", "round", nil)

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert heex =~ "var(--avatar-codex"
    end

    test "no literal hex or rgb color values in rendered HTML" do
      iur = avatar_iur("PC", nil, "pascal", "large", "square", "Pascal")

      {:ok, heex} = LiveUIAdapter.render(iur)
      refute heex =~ ~r/#[0-9a-fA-F]{3,6}\b/
      refute heex =~ ~r/\brgb\s*\(/
    end
  end

  defp avatar_iur(initials, image_src, variant, size, shape, aria_label) do
    %{
      "type" => "avatar",
      "id" => "avatar-1",
      "props" => %{
        "initials" => initials,
        "image_src" => image_src,
        "variant" => variant,
        "size" => size,
        "shape" => shape,
        "aria_label" => aria_label,
        "class" => ""
      },
      "children" => [],
      "metadata" => %{}
    }
  end

  describe "presence_dot widget rendering" do
    test "renders span with ash-presence-dot class and data-state" do
      iur = presence_dot_iur("live", "medium", nil)

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert heex =~ "ash-presence-dot"
      assert heex =~ ~s(data-state="live")
    end

    test "state idle produces --presence-idle token in style" do
      iur = presence_dot_iur("idle", "medium", nil)

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert heex =~ "var(--presence-idle"
      assert heex =~ ~s(data-state="idle")
    end

    test "state warn produces --presence-warn token in style" do
      iur = presence_dot_iur("warn", "medium", nil)

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert heex =~ "var(--presence-warn"
    end

    test "small size applies ash-presence-dot-small class" do
      iur = presence_dot_iur("live", "small", nil)

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert heex =~ "ash-presence-dot-small"
      refute heex =~ "ash-presence-dot-medium"
      refute heex =~ "ash-presence-dot-large"
    end

    test "large size applies ash-presence-dot-large class" do
      iur = presence_dot_iur("live", "large", nil)

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert heex =~ "ash-presence-dot-large"
    end

    test "medium size applies ash-presence-dot-medium class by default" do
      iur = presence_dot_iur("live", "medium", nil)

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert heex =~ "ash-presence-dot-medium"
    end

    test "aria_label produces aria-label attribute and omits aria-hidden" do
      iur = presence_dot_iur("live", "medium", "Active")

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert heex =~ ~s(aria-label="Active")
      refute heex =~ ~s(aria-hidden="true")
    end

    test "no aria_label produces aria-hidden=true" do
      iur = presence_dot_iur("live", "medium", nil)

      {:ok, heex} = LiveUIAdapter.render(iur)
      assert heex =~ ~s(aria-hidden="true")
      refute heex =~ "aria-label="
    end

    test "rendered HTML contains no literal hex color values" do
      for state <- ["live", "idle", "warn", "muted", "quiet"] do
        iur = presence_dot_iur(state, "medium", nil)
        {:ok, heex} = LiveUIAdapter.render(iur)

        refute heex =~ ~r/#[0-9a-fA-F]{3,6}\b/,
               "found literal hex color value in presence_dot HTML for state #{state}"
      end
    end
  end

  defp presence_dot_iur(state, size, aria_label) do
    %{
      "type" => "screen",
      "id" => "test-screen",
      "name" => "test",
      "layout" => "column",
      "children" => [
        %{
          "type" => "presence_dot",
          "id" => "dot-1",
          "name" => "dot",
          "props" => %{
            "state" => state,
            "size" => size,
            "aria_label" => aria_label,
            "class" => ""
          },
          "children" => [],
          "metadata" => %{}
        }
      ],
      "bindings" => [],
      "metadata" => %{}
    }
  end

  describe "list_item_multi_column widget" do
    defp limc_iur(props, children \\ []) do
      %{
        "type" => "list_item_multi_column",
        "id" => "limc-1",
        "props" => props,
        "children" => children,
        "metadata" => %{},
        "bindings" => []
      }
    end

    test "admission: storage accepts list_item_multi_column type" do
      assert AshUI.DSL.Storage.valid_widget_type?("list_item_multi_column")
    end

    test "renders as <button> by default with ash-list-item-multi-column class" do
      {:ok, heex} = LiveUIAdapter.render(limc_iur(%{"columns" => "1fr"}))

      assert heex =~ "<button"
      assert heex =~ "ash-list-item-multi-column"
    end

    test "grid-template-columns value appears in style attribute" do
      {:ok, heex} = LiveUIAdapter.render(limc_iur(%{"columns" => "2fr 1fr 1fr"}))

      assert heex =~ "grid-template-columns: 2fr 1fr 1fr"
    end

    test "phx-click reflects event prop" do
      {:ok, heex} = LiveUIAdapter.render(limc_iur(%{"event" => "pick_item"}))

      assert heex =~ ~s(phx-click="pick_item")
    end

    test "phx-value key reflects event_value_key prop with row_id value" do
      {:ok, heex} =
        LiveUIAdapter.render(limc_iur(%{"row_id" => "item-42", "event_value_key" => "item_id"}))

      assert heex =~ ~s(phx-value-item_id="item-42")
    end

    test "data-active reflects active prop" do
      {:ok, heex_false} = LiveUIAdapter.render(limc_iur(%{"active" => false}))
      {:ok, heex_true} = LiveUIAdapter.render(limc_iur(%{"active" => true}))

      assert heex_false =~ ~s(data-active="false")
      assert heex_true =~ ~s(data-active="true")
    end

    test "renders as <a> when href prop is set" do
      {:ok, heex} = LiveUIAdapter.render(limc_iur(%{"href" => "/docs/42"}))

      assert heex =~ "<a"
      assert heex =~ ~s(href="/docs/42")
      refute heex =~ "<button"
      refute heex =~ "phx-click"
    end

    test "children render inside the row element" do
      children = [
        %{
          "type" => "text",
          "id" => "c1",
          "props" => %{"content" => "Col A"},
          "children" => [],
          "metadata" => %{}
        }
      ]

      {:ok, heex} = LiveUIAdapter.render(limc_iur(%{"columns" => "1fr"}, children))

      assert heex =~ "Col A"
    end
  end

  describe "artifact_row widget" do
    defp artifact_row_iur(props, children \\ []) do
      %{
        "type" => "artifact_row",
        "id" => "ar-1",
        "props" => props,
        "children" => children,
        "metadata" => %{},
        "bindings" => []
      }
    end

    test "admission: storage accepts artifact_row type" do
      assert AshUI.DSL.Storage.valid_widget_type?("artifact_row")
    end

    test "renders as <button> by default with ash-artifact-row class" do
      {:ok, heex} = LiveUIAdapter.render(artifact_row_iur(%{"title" => "My Artifact"}))

      assert heex =~ "<button"
      assert heex =~ "ash-artifact-row"
    end

    test "title renders in ash-artifact-row-title span" do
      {:ok, heex} = LiveUIAdapter.render(artifact_row_iur(%{"title" => "AGREEMENT final.pdf"}))

      assert heex =~ "ash-artifact-row-title"
      assert heex =~ "AGREEMENT final.pdf"
    end

    test "meta renders in ash-artifact-row-meta span when non-empty" do
      {:ok, heex} =
        LiveUIAdapter.render(artifact_row_iur(%{"title" => "T", "meta" => "STORED v3"}))

      assert heex =~ "ash-artifact-row-meta"
      assert heex =~ "STORED v3"
    end

    test "meta span is absent when meta prop is empty string" do
      {:ok, heex} = LiveUIAdapter.render(artifact_row_iur(%{"title" => "T", "meta" => ""}))

      refute heex =~ "ash-artifact-row-meta"
    end

    test "phx-click reflects event prop" do
      {:ok, heex} =
        LiveUIAdapter.render(artifact_row_iur(%{"title" => "T", "event" => "open_artifact"}))

      assert heex =~ ~s(phx-click="open_artifact")
    end

    test "phx-value key reflects event_value_key prop with row_id value" do
      {:ok, heex} =
        LiveUIAdapter.render(
          artifact_row_iur(%{"title" => "T", "row_id" => "ar-42", "event_value_key" => "doc_id"})
        )

      assert heex =~ ~s(phx-value-doc_id="ar-42")
    end

    test "data-active reflects active prop" do
      {:ok, heex_false} =
        LiveUIAdapter.render(artifact_row_iur(%{"title" => "T", "active" => false}))

      {:ok, heex_true} =
        LiveUIAdapter.render(artifact_row_iur(%{"title" => "T", "active" => true}))

      assert heex_false =~ ~s(data-active="false")
      assert heex_true =~ ~s(data-active="true")
    end

    test "renders as <a> when href prop is set, omitting phx-click" do
      {:ok, heex} =
        LiveUIAdapter.render(artifact_row_iur(%{"title" => "T", "href" => "/artifacts/42"}))

      assert heex =~ "<a"
      assert heex =~ ~s(href="/artifacts/42")
      refute heex =~ "<button"
      refute heex =~ "phx-click"
    end

    test "trailing slot children render inside ash-artifact-row-trailing wrapper" do
      children = [
        %{
          "type" => "text",
          "id" => "badge-1",
          "props" => %{"content" => "Origin"},
          "children" => [],
          "metadata" => %{}
        }
      ]

      {:ok, heex} = LiveUIAdapter.render(artifact_row_iur(%{"title" => "T"}, children))

      assert heex =~ "ash-artifact-row-trailing"
      assert heex =~ "Origin"
    end
  end
end
