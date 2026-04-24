defmodule Phase18ExampleGenerator do
  alias AshUI.Examples.Phase18

  def run(args) do
    definitions =
      case args do
        [] ->
          Phase18.definitions()

        sections ->
          sections
          |> Enum.map(&String.to_atom/1)
          |> Enum.flat_map(&Phase18.definitions_for/1)
      end

    shared_theme_css = File.read!(Path.expand("../examples/ash_hq_theme_tokens.css", __DIR__))

    File.mkdir_p!(Path.expand("../examples", __DIR__))

    Enum.each(definitions, fn definition ->
      directory = definition.directory
      project_path = Phase18.project_path(directory)
      root_module = inspect(Phase18.example_module(directory))
      module_basename = directory
      camel_directory = Macro.camelize(directory)
      app_atom = Phase18.app_atom(directory)
      screen_module = "#{root_module}.Examples.#{camel_directory}Screen"

      files = %{
        "README.md" => render_readme(definition),
        "mix.exs" => render_mix_exs(app_atom, root_module, definition),
        "config/config.exs" => render_config_exs(app_atom, root_module),
        "config/dev.exs" => render_dev_exs(app_atom),
        "assets/css/app.css" => render_app_css(shared_theme_css, definition),
        "lib/ash_ui_examples/#{module_basename}.ex" =>
          render_app_module(root_module, screen_module, definition)
      }

      Enum.each(files, fn {relative_path, content} ->
        target = Path.join(project_path, relative_path)
        File.mkdir_p!(Path.dirname(target))
        File.write!(target, content)
      end)
    end)
  end

  defp render_readme(definition) do
    """
    # #{definition.title}

    This standalone Phoenix LiveView app demonstrates the `#{definition.directory}` example from
    the Phase 18 Ash UI suite.

    It preserves the sibling `unified_ui` directory name while rebuilding the
    example through resource-authority screens, related element resources, and the
    shared Ash HQ shell.

    ## Run

    From this directory:

    `mix deps.get`
    `mix phx.server`

    The app mounts at `http://127.0.0.1:5000/` by default.

    ## Try It

    #{try_it_text(definition)}

    ## Expect

    #{definition.story_text}

    #{definition.signal_text}

    ## Validate

    `mix run --no-start -e "IO.puts(#{inspect(Phase18.screen_name(definition.directory))})"`
    """
  end

  defp render_mix_exs(app_atom, root_module, _definition) do
    """
    defmodule #{root_module}.MixProject do
      use Mix.Project

      def project do
        [
          app: #{inspect(app_atom)},
          version: "0.1.0",
          elixir: "~> 1.15",
          start_permanent: Mix.env() == :prod,
          deps: deps(),
          aliases: aliases()
        ]
      end

      def application do
        [
          mod: {#{root_module}.Application, []},
          extra_applications: [:logger]
        ]
      end

      defp deps do
        [
          {:ash_ui, path: "../.."},
          {:phoenix, "~> 1.7"},
          {:phoenix_html, "~> 4.1"},
          {:phoenix_live_view, "~> 1.0"},
          {:plug_cowboy, "~> 2.7"}
        ]
      end

      defp aliases do
        [
          "example.start": ["phx.server"]
        ]
      end
    end
    """
  end

  defp render_config_exs(app_atom, root_module) do
    """
    import Config

    config #{inspect(app_atom)},
      ecto_repos: []

    config #{inspect(app_atom)}, #{root_module}.Web.Endpoint,
      url: [host: "127.0.0.1"],
      http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT", "5000"))],
      secret_key_base: String.duplicate("ashuiexample", 6),
      server: true,
      live_view: [signing_salt: "ashuiph18"]

    config :ash_ui, :ui_storage,
      domain: #{root_module}.UiStorageDomain,
      resources: [
        screen: #{root_module}.UiScreen,
        element: #{root_module}.UiElement,
        binding: #{root_module}.UiBinding
      ],
      repo: nil

    config :ash_ui, :ash_domains, [#{root_module}.RuntimeDomain]

    import_config "\#{config_env()}.exs"
    """
  end

  defp render_dev_exs(app_atom) do
    """
    import Config

    config #{inspect(app_atom)}, dev_routes: true
    """
  end

  defp render_app_css(shared_theme_css, definition) do
    """
    #{String.trim_trailing(shared_theme_css)}

    .ashui-example-live-surface {
      position: relative;
      z-index: 1;
    }

    .ashui-example-shell-header {
      display: grid;
      gap: 0.8rem;
      margin-bottom: 1.5rem;
    }

    .ashui-example-shell-kicker {
      color: var(--ashui-example-accent);
      font-size: 0.8rem;
      letter-spacing: 0.18em;
      text-transform: uppercase;
    }

    .ashui-example-shell-title {
      margin: 0;
      color: var(--ashui-example-copy-strong);
      font-size: clamp(2rem, 3vw, 3rem);
      line-height: 1.05;
    }

    .ashui-example-shell-summary {
      max-width: 46rem;
      margin: 0;
      color: var(--ashui-example-copy-muted);
    }

    .ashui-example-subject {
      width: 100%;
    }

    .ashui-example-copy {
      font-size: 1rem;
      line-height: 1.7;
    }

    .ashui-example-copy-wide {
      max-width: 42rem;
    }

    .ashui-example-link {
      color: var(--ashui-example-accent);
      font-weight: 700;
      text-decoration: none;
    }

    .ashui-example-link:hover,
    .ashui-example-link:focus-visible {
      text-decoration: underline;
    }

    .ashui-example-icon {
      align-items: center;
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid var(--ashui-example-border-soft);
      border-radius: 999px;
      display: inline-flex;
      gap: 0.65rem;
      padding: 0.8rem 1rem;
    }

    .ashui-example-image {
      border-radius: 1.2rem;
      box-shadow: var(--ashui-example-panel-shadow);
      display: block;
      max-width: min(100%, 28rem);
      overflow: hidden;
    }

    .ashui-example-box {
      min-height: 12rem;
    }

    /* #{definition.title} */
    """
  end

  defp render_app_module(root_module, screen_module, definition) do
    screen_name = Phase18.screen_name(definition.directory)

    current_user = %{
      id: "reviewer-#{definition.directory}",
      name: "Example Reviewer",
      role: :admin,
      active: true
    }

    preview_value =
      if definition.preview_field do
        Map.get(definition.seed_state, definition.preview_field, "unhydrated")
      else
        "No preview value"
      end

    support_relationship? = definition.support_notice not in [nil, ""]

    EEx.eval_string(
      ~S'''
      defmodule <%= root_module %> do
        @moduledoc """
        Standalone resource-authority Ash UI app for the `<%= definition.directory %>` example.
        """

        use Phoenix.Component

        alias AshUI.LiveView.EventHandler
        alias AshUI.LiveView.Integration
        alias AshUI.Rendering.LiveUIAdapter
        alias AshUI.Resource.Authority

        @directory "<%= definition.directory %>"
        @screen_name "<%= screen_name %>"
        @definition <%= inspect(definition, pretty: true) %>
        @theme_css File.read!(Path.expand("../../assets/css/app.css", __DIR__))

        def app, do: <%= inspect(AshUI.Examples.Phase18.app_atom(definition.directory)) %>
        def definition, do: @definition
        def title, do: @definition.title
        def theme_css, do: @theme_css
        def screen_name, do: @screen_name

        def ui_storage do
          [
            domain: <%= root_module %>.UiStorageDomain,
            resources: [
              screen: <%= root_module %>.UiScreen,
              element: <%= root_module %>.UiElement,
              binding: <%= root_module %>.UiBinding
            ],
            repo: nil
          ]
        end

        def runtime_domains, do: [<%= root_module %>.RuntimeDomain]

        def current_user, do: <%= inspect(current_user, pretty: true) %>

        def seed_state do
          Map.merge(
            %{
              id: "state-" <> @directory,
              current_value: "Ready",
              display_value: "Ready",
              status: "Mounted",
              submitted_value: "Not submitted",
              selected_value: "primary",
              checked: false,
              enabled: false,
              notes: ""
            },
            <%= inspect(definition.seed_state, pretty: true) %>
          )
        end

        def reset! do
          reset_resource!(<%= root_module %>.Runtime.ExampleState, <%= root_module %>.RuntimeDomain)
          reset_resource!(<%= root_module %>.UiBinding, <%= root_module %>.UiStorageDomain)
          reset_resource!(<%= root_module %>.UiElement, <%= root_module %>.UiStorageDomain)
          reset_resource!(<%= root_module %>.UiScreen, <%= root_module %>.UiStorageDomain)
          :ok
        end

        def seed!(opts \\ []) do
          actor = Keyword.get(opts, :actor, current_user())
          reset!()
          {:ok, _state} =
            Ash.create(
              <%= root_module %>.Runtime.ExampleState,
              seed_state(),
              domain: <%= root_module %>.RuntimeDomain,
              authorize?: false
            )

          {:ok, screen} =
            Authority.create(
              <%= screen_module %>,
              actor: actor,
              name: @screen_name,
              ui_storage: ui_storage()
            )

          %{
            actor: actor,
            screen: screen,
            screen_name: @screen_name,
            ui_storage: ui_storage()
          }
        end

        def build_socket(extra_assigns \\ %{}) do
          base_assigns = %{
            __changed__: %{},
            flash: %{},
            current_user: current_user(),
            ash_ui_storage: ui_storage(),
            ash_ui_domains: runtime_domains()
          }

          %Phoenix.LiveView.Socket{assigns: Map.merge(base_assigns, extra_assigns)}
        end

        def mount_seeded!(opts \\ []) do
          seeded = seed!(opts)
          socket = build_socket(%{current_user: seeded.actor, ash_ui_storage: seeded.ui_storage, ash_ui_domains: runtime_domains()})
          {:ok, mounted_socket} = Integration.mount_ui_screen(socket, seeded.screen_name, %{})
          {:ok, mounted_socket} = EventHandler.wire_handlers(mounted_socket)
          Map.put(seeded, :socket, mounted_socket)
        end

        def rendered_ui(assigns) do
          iur =
            assigns[:ash_ui_iur] ||
              Integration.hydrate_iur(assigns[:ash_ui_base_iur], assigns[:ash_ui_bindings] || %{})

          {:ok, markup} =
            LiveUIAdapter.render(
              iur,
              bindings: Map.values(assigns[:ash_ui_bindings] || %{}),
              event_prefix: "ash_ui",
              force_fallback: true
            )

          markup
        end

        defp reset_resource!(resource, domain) do
          resource
          |> Ash.read!(domain: domain, authorize?: false)
          |> Enum.each(&Ash.destroy!(&1, domain: domain, authorize?: false))
        end

        defmodule Application do
          use Elixir.Application

          def start(_type, _args) do
            children = [
              {Phoenix.PubSub, name: <%= root_module %>.PubSub},
              <%= root_module %>.Web.Endpoint
            ]

            Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
          end
        end

        defmodule RuntimeDomain do
          use Ash.Domain, validate_config_inclusion?: false

          resources do
            resource(<%= root_module %>.Runtime.ExampleState)
          end
        end

        defmodule Runtime.ExampleState do
          use Ash.Resource, domain: <%= root_module %>.RuntimeDomain, data_layer: Ash.DataLayer.Ets

          ets do
            private?(true)
          end

          attributes do
            attribute :id, :string do
              primary_key?(true)
              allow_nil?(false)
            end

            attribute :current_value, :string, default: "Ready"
            attribute :display_value, :string, default: "Ready"
            attribute :status, :string, default: "Mounted"
            attribute :submitted_value, :string, default: "Not submitted"
            attribute :selected_value, :string, default: "primary"
            attribute :checked, :boolean, default: false
            attribute :enabled, :boolean, default: false
            attribute :notes, :string, default: ""
          end

          actions do
            defaults([:read, :destroy])

            create :create do
              primary?(true)
              accept([:id, :current_value, :display_value, :status, :submitted_value, :selected_value, :checked, :enabled, :notes])
            end

            update :update do
              primary?(true)
              accept([:current_value, :display_value, :status, :submitted_value, :selected_value, :checked, :enabled, :notes])
            end
          end
        end

        defmodule UiStorageDomain do
          use Ash.Domain, validate_config_inclusion?: false

          resources do
            resource(<%= root_module %>.UiScreen)
            resource(<%= root_module %>.UiElement)
            resource(<%= root_module %>.UiBinding)
          end
        end

        defmodule UiScreen do
          use Ash.Resource,
            domain: <%= root_module %>.UiStorageDomain,
            authorizers: [Ash.Policy.Authorizer],
            data_layer: Ash.DataLayer.Ets

          ets do
            private?(true)
          end

          attributes do
            uuid_primary_key(:id)
            attribute(:name, :string, allow_nil?: false)
            attribute(:unified_dsl, :map, default: %{})
            attribute(:layout, :atom, default: :default)
            attribute(:route, :string)
            attribute(:metadata, :map, default: %{})
            attribute(:active, :boolean, default: true)
            attribute(:version, :integer, default: 1)
            create_timestamp(:inserted_at)
            update_timestamp(:updated_at)
          end

          relationships do
            has_many :elements, <%= root_module %>.UiElement do
              destination_attribute(:screen_id)
            end

            has_many :bindings, <%= root_module %>.UiBinding do
              destination_attribute(:screen_id)
            end
          end

          actions do
            defaults([:read])

            read :mount do
              get?(true)

              argument :user_id, :string do
                allow_nil?(false)
              end

              argument :params, :map do
                allow_nil?(false)
                default(%{})
              end
            end

            create :create do
              primary?(true)
              accept([:name, :unified_dsl, :layout, :route, :metadata, :active, :version])
            end

            update :update do
              primary?(true)
              accept([:name, :unified_dsl, :layout, :route, :metadata, :active])
              change(increment(:version))
            end

            destroy :destroy do
              primary?(true)
            end
          end

          policies do
            bypass actor_absent() do
              authorize_if(always())
            end

            bypass actor_attribute_equals(:role, :admin) do
              authorize_if(always())
            end

            policy action([:read, :mount]) do
              authorize_if({AshUI.Authorization.Checks.ScreenAccess, mode: :read})
            end

            policy action(:create) do
              authorize_if({AshUI.Authorization.Checks.ScreenAccess, mode: :manage})
            end

            policy action([:update, :destroy]) do
              authorize_if({AshUI.Authorization.Checks.ScreenAccess, mode: :manage})
            end
          end
        end

        defmodule UiElement do
          use Ash.Resource,
            domain: <%= root_module %>.UiStorageDomain,
            authorizers: [Ash.Policy.Authorizer],
            data_layer: Ash.DataLayer.Ets

          ets do
            private?(true)
          end

          attributes do
            uuid_primary_key(:id)
            attribute(:type, :atom, allow_nil?: false)
            attribute(:props, :map, default: %{})
            attribute(:variants, {:array, :atom}, default: [])
            attribute(:position, :integer, default: 0)
            attribute(:metadata, :map, default: %{})
            attribute(:active, :boolean, default: true)
            attribute(:version, :integer, default: 1)
            create_timestamp(:inserted_at)
            update_timestamp(:updated_at)
          end

          relationships do
            belongs_to :screen, <%= root_module %>.UiScreen do
              attribute_type(:uuid)
              allow_nil?(true)
            end

            has_many :bindings, <%= root_module %>.UiBinding do
              destination_attribute(:element_id)
            end
          end

          actions do
            defaults([:read, :destroy])

            create :create do
              primary?(true)
              accept([:type, :props, :variants, :position, :screen_id, :metadata, :active, :version])
            end

            update :update do
              primary?(true)
              accept([:type, :props, :variants, :position, :screen_id, :metadata, :active])
              change(increment(:version))
            end
          end

          policies do
            bypass actor_absent() do
              authorize_if(always())
            end

            bypass actor_attribute_equals(:role, :admin) do
              authorize_if(always())
            end

            policy action_type(:read) do
              authorize_if({AshUI.Authorization.Checks.ElementAccess, mode: :read})
            end

            policy action([:create, :update, :destroy]) do
              authorize_if({AshUI.Authorization.Checks.ElementAccess, mode: :manage})
            end
          end
        end

        defmodule UiBinding do
          use Ash.Resource,
            domain: <%= root_module %>.UiStorageDomain,
            authorizers: [Ash.Policy.Authorizer],
            data_layer: Ash.DataLayer.Ets

          ets do
            private?(true)
          end

          attributes do
            uuid_primary_key(:id)
            attribute(:source, :map, allow_nil?: false, default: %{})
            attribute(:target, :string, allow_nil?: false)
            attribute(:binding_type, :atom, constraints: [one_of: [:value, :list, :action]])
            attribute(:transform, :map, default: %{})
            attribute(:metadata, :map, default: %{})
            attribute(:active, :boolean, default: true)
            attribute(:version, :integer, default: 1)
            create_timestamp(:inserted_at)
            update_timestamp(:updated_at)
          end

          relationships do
            belongs_to :element, <%= root_module %>.UiElement do
              attribute_type(:uuid)
              allow_nil?(true)
            end

            belongs_to :screen, <%= root_module %>.UiScreen do
              attribute_type(:uuid)
              allow_nil?(true)
            end
          end

          actions do
            defaults([:read, :destroy])

            create :create do
              primary?(true)
              accept([:source, :target, :binding_type, :transform, :element_id, :screen_id, :metadata, :active, :version])
            end

            update :update do
              primary?(true)
              accept([:source, :target, :binding_type, :transform, :element_id, :screen_id, :metadata, :active])
              change(increment(:version))
            end
          end

          policies do
            bypass actor_absent() do
              authorize_if(always())
            end

            bypass actor_attribute_equals(:role, :admin) do
              authorize_if(always())
            end

            policy action_type(:read) do
              authorize_if({AshUI.Authorization.Checks.BindingAccess, mode: :read})
            end

            policy action([:create, :update, :destroy]) do
              authorize_if({AshUI.Authorization.Checks.BindingAccess, mode: :manage})
            end
          end
        end

        defmodule AuthoringDomain do
          use Ash.Domain, validate_config_inclusion?: false

          resources do
            resource(<%= screen_module %>)
            resource(<%= root_module %>.Examples.<%= Macro.camelize(definition.directory) %>DemoPanelElement)
            resource(<%= root_module %>.Examples.<%= Macro.camelize(definition.directory) %>SubjectElement)
            resource(<%= root_module %>.Examples.<%= Macro.camelize(definition.directory) %>PreviewElement)
            resource(<%= root_module %>.Examples.<%= Macro.camelize(definition.directory) %>StoryTextElement)
            resource(<%= root_module %>.Examples.<%= Macro.camelize(definition.directory) %>SignalTextElement)
            <%= if support_relationship? do %>resource(<%= root_module %>.Examples.<%= Macro.camelize(definition.directory) %>SupportNoticeElement)<% end %>
          end
        end

        defmodule ExampleElementBase do
          defmacro __using__(_opts) do
            quote do
              use Ash.Resource,
                domain: <%= root_module %>.AuthoringDomain,
                data_layer: Ash.DataLayer.Ets

              use AshUI.Resource.DSL.Element

              ets do
                private?(true)
              end

              attributes do
                uuid_primary_key(:id)
                attribute(:screen_id, :uuid, allow_nil?: true)
                attribute(:parent_id, :uuid, allow_nil?: true)
              end

              actions do
                defaults([:read])
              end
            end
          end
        end

        defmodule Examples.<%= Macro.camelize(definition.directory) %>DemoPanelElement do
          use <%= root_module %>.ExampleElementBase

          relationships do
            has_many :subjects, <%= root_module %>.Examples.<%= Macro.camelize(definition.directory) %>SubjectElement do
              destination_attribute(:parent_id)
            end

            has_many :previews, <%= root_module %>.Examples.<%= Macro.camelize(definition.directory) %>PreviewElement do
              destination_attribute(:parent_id)
            end

            <%= if support_relationship? do %>
            has_many :support_notices, <%= root_module %>.Examples.<%= Macro.camelize(definition.directory) %>SupportNoticeElement do
              destination_attribute(:parent_id)
            end
            <% end %>
          end

          ui_relationships do
            relationship :subjects do
              kind :child
              slot :body
              placement :append
              order 0
            end

            relationship :previews do
              kind :child
              slot :body
              placement :append
              order 10
            end

            <%= if support_relationship? do %>
            relationship :support_notices do
              kind :child
              slot :body
              placement :append
              order 20
            end
            <% end %>
          end

          ui_element do
            type :card
            props %{title: <%= inspect(definition.title) %>, class: "ashui-example-panel"}
            metadata %{id: "example-<%= definition.directory %>-demo", section: "demo", slot: "body", position: 0}
          end
        end

        defmodule Examples.<%= Macro.camelize(definition.directory) %>SubjectElement do
          use <%= root_module %>.ExampleElementBase

          ui_element do
            type <%= inspect(definition.subject_type) %>
            props <%= inspect(definition.subject_props, pretty: true) %>
            metadata %{id: "example-<%= definition.directory %>-subject", section: "demo", slot: "body", position: 1}
          end

          <%= if definition.subject_binding do %>
          ui_bindings do
            binding <%= inspect(definition.subject_binding.id) %> do
              source %{resource: "ExampleState", field: <%= inspect(definition.subject_binding.field) %>, id: "state-<%= definition.directory %>"}
              target <%= inspect(definition.subject_binding.target) %>
              binding_type :value
              transform <%= inspect(definition.subject_binding.transform, pretty: true) %>
              metadata %{owner: "subject", owner_signal: "change"}
            end
          end
          <% end %>

          <%= if definition.subject_action do %>
          ui_actions do
            action <%= inspect(definition.subject_action.id) %> do
              signal <%= inspect(definition.subject_action.signal) %>
              source %{resource: "ExampleState", action: "update", id: "state-<%= definition.directory %>"}
              target "submit"
              transform %{params: <%= inspect(definition.subject_action.params, pretty: true) %>}
              metadata <%= inspect(definition.subject_action.metadata, pretty: true) %>
            end
          end
          <% end %>
        end

        defmodule Examples.<%= Macro.camelize(definition.directory) %>PreviewElement do
          use <%= root_module %>.ExampleElementBase

          ui_element do
            type :stat
            props %{title: <%= inspect(definition.preview_title || "Current value") %>, value: <%= inspect(preview_value) %>}
            variants [:primary]
            metadata %{id: "example-<%= definition.directory %>-preview", section: "demo", slot: "body", position: 2}
          end

          <%= if definition.preview_field do %>
          ui_bindings do
            binding :preview_value do
              source %{resource: "ExampleState", field: <%= inspect(definition.preview_field) %>, id: "state-<%= definition.directory %>"}
              target "value"
              binding_type :value
              transform %{}
              metadata %{owner: "preview"}
            end
          end
          <% end %>
        end

        defmodule Examples.<%= Macro.camelize(definition.directory) %>StoryTextElement do
          use <%= root_module %>.ExampleElementBase

          ui_element do
            type :text
            props %{content: <%= inspect(definition.story_text) %>, class: "ashui-example-code-surface"}
            metadata %{id: "example-<%= definition.directory %>-story", section: "story", slot: "body", position: 10}
          end
        end

        defmodule Examples.<%= Macro.camelize(definition.directory) %>SignalTextElement do
          use <%= root_module %>.ExampleElementBase

          ui_element do
            type :text
            props %{content: <%= inspect(definition.signal_text) %>, class: "ashui-example-code-surface"}
            metadata %{id: "example-<%= definition.directory %>-signal-preview", section: "signal_preview", slot: "body", position: 20}
          end
        end

        <%= if support_relationship? do %>
        defmodule Examples.<%= Macro.camelize(definition.directory) %>SupportNoticeElement do
          use <%= root_module %>.ExampleElementBase

          ui_element do
            type :text
            props %{content: <%= inspect(definition.support_notice) %>, class: "ashui-example-focus-ring"}
            metadata %{id: "example-<%= definition.directory %>-support-note", section: "demo", slot: "body", position: 3}
          end
        end
        <% end %>

        defmodule Examples.<%= Macro.camelize(definition.directory) %>Screen do
          use Ash.Resource,
            domain: <%= root_module %>.AuthoringDomain,
            data_layer: Ash.DataLayer.Ets

          use AshUI.Resource.DSL.Screen

          ets do
            private?(true)
          end

          attributes do
            uuid_primary_key(:id)
          end

          actions do
            defaults([:read])
          end

          relationships do
            has_many :demo_panels, <%= root_module %>.Examples.<%= Macro.camelize(definition.directory) %>DemoPanelElement do
              destination_attribute(:screen_id)
            end

            has_many :story_texts, <%= root_module %>.Examples.<%= Macro.camelize(definition.directory) %>StoryTextElement do
              destination_attribute(:screen_id)
            end

            has_many :signal_texts, <%= root_module %>.Examples.<%= Macro.camelize(definition.directory) %>SignalTextElement do
              destination_attribute(:screen_id)
            end
          end

          ui_relationships do
            relationship :demo_panels do
              kind :child
              slot :body
              placement :append
              order 0
            end

            relationship :story_texts do
              kind :child
              slot :body
              placement :append
              order 10
            end

            relationship :signal_texts do
              kind :child
              slot :body
              placement :append
              order 20
            end
          end

          ui_screen do
            layout :column
            route "/"
            metadata %{title: <%= inspect(definition.title) %>, example_directory: <%= inspect(definition.directory) %>, shell_id: "example-<%= definition.directory %>-shell"}
          end
        end

        defmodule ExampleSeeds do
          def seed!(opts \\ []), do: <%= root_module %>.seed!(opts)
          def reset!, do: <%= root_module %>.reset!()
        end

        defmodule Web.Router do
          use Phoenix.Router
          import Phoenix.LiveView.Router

          pipeline :browser do
            plug :accepts, ["html"]
            plug :fetch_session
            plug :protect_from_forgery
            plug :put_secure_browser_headers
          end

          scope "/", <%= root_module %>.Web do
            pipe_through :browser
            live "/", ExampleLive
          end
        end

        defmodule Web.Endpoint do
          use Phoenix.Endpoint, otp_app: <%= inspect(AshUI.Examples.Phase18.app_atom(definition.directory)) %>

          @session_options [
            store: :cookie,
            key: "_ash_ui_example_key",
            signing_salt: "ashuiph18"
          ]

          socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

          plug Plug.RequestId
          plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
          plug Plug.Session, @session_options
          plug <%= root_module %>.Web.Router
        end

        defmodule Web.Components.ExampleShell do
          use Phoenix.Component

          attr :title, :string, required: true
          attr :directory, :string, required: true
          attr :summary, :string, required: true
          attr :theme_css, :string, required: true
          slot :inner_block, required: true

          def example_shell(assigns) do
            ~H"""
            <style><%%= Phoenix.HTML.raw(@theme_css) %></style>
            <main id={"example-#{@directory}-shell"} class="ashui-example-shell">
              <header class="ashui-example-shell-header">
                <p class="ashui-example-shell-kicker">Ash UI Example</p>
                <h1 class="ashui-example-shell-title"><%%= @title %></h1>
                <p class="ashui-example-shell-summary"><%%= @summary %></p>
              </header>
              <section class="ashui-example-live-surface">
                <%%= render_slot(@inner_block) %>
              </section>
            </main>
            """
          end
        end

        defmodule Web.ExampleLive do
          use Phoenix.LiveView

          alias <%= root_module %>.Web.Components.ExampleShell
          alias AshUI.LiveView.EventHandler
          alias AshUI.LiveView.Integration

          def mount(params, _session, socket) do
            _ = <%= root_module %>.seed!()

            socket =
              socket
              |> Phoenix.Component.assign(:current_user, <%= root_module %>.current_user())
              |> Phoenix.Component.assign(:ash_ui_storage, <%= root_module %>.ui_storage())
              |> Phoenix.Component.assign(:ash_ui_domains, <%= root_module %>.runtime_domains())
              |> Phoenix.Component.assign(:page_title, <%= inspect(definition.title) %>)
              |> Phoenix.Component.assign(:example_directory, <%= inspect(definition.directory) %>)
              |> Phoenix.Component.assign(:theme_css, <%= root_module %>.theme_css())

            with {:ok, socket} <- Integration.mount_ui_screen(socket, <%= inspect(screen_name) %>, params),
                 {:ok, socket} <- EventHandler.wire_handlers(socket) do
              {:ok, refresh_rendered_ui(socket)}
            else
              {:error, reason} ->
                {:ok, Phoenix.Component.assign(socket, :rendered_ui, "Mount failed: #{inspect(reason)}")}
            end
          end

          def handle_event("ash_ui_change", params, socket) do
            case EventHandler.handle_value_change(params, socket) do
              {:noreply, socket} -> {:noreply, refresh_rendered_ui(socket)}
              other -> other
            end
          end

          def handle_event("ash_ui_action", params, socket) do
            case EventHandler.handle_action_event(params, socket) do
              {:reply, payload, socket} -> {:reply, payload, refresh_rendered_ui(socket)}
              {:noreply, socket} -> {:noreply, refresh_rendered_ui(socket)}
            end
          end

          def render(assigns) do
            ~H"""
            <ExampleShell.example_shell
              title={@page_title}
              directory={@example_directory}
              summary={<%= inspect(definition.story_text) %>}
              theme_css={@theme_css}
            >
              <%%= Phoenix.HTML.raw(@rendered_ui || "") %>
            </ExampleShell.example_shell>
            """
          end

          defp refresh_rendered_ui(socket) do
            Phoenix.Component.assign(socket, :rendered_ui, <%= root_module %>.rendered_ui(socket.assigns))
          end
        end
      end
      ''',
      [
        root_module: root_module,
        screen_module: screen_module,
        definition: definition,
        current_user: current_user,
        screen_name: screen_name,
        preview_value: preview_value,
        support_relationship?: support_relationship?
      ],
      trim: true
    )
  end

  defp try_it_text(%{subject_action: %{signal: :click}}),
    do: "Click the primary subject and watch the persisted preview surface update."

  defp try_it_text(%{subject_binding: %{target: "content"}}),
    do:
      "Review the bound content and confirm the preview card reflects the same persisted runtime state."

  defp try_it_text(%{subject_type: :"custom:link"}),
    do:
      "Inspect the navigation affordance and confirm the support note explains the custom-surface boundary."

  defp try_it_text(_definition),
    do: "Review the focused subject panel together with the story and signal surfaces."
end

Phase18ExampleGenerator.run(System.argv())
