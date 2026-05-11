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
end
