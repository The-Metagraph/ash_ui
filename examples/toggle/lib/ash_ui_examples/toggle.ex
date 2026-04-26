defmodule AshUIExamples.Toggle do
  @moduledoc """
  Standalone resource-authority Ash UI app for the `toggle` example.
  """

  use Phoenix.Component

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.{DesktopUIAdapter, ElmUIAdapter, LiveUIAdapter}
  alias AshUI.Resource.Authority

  @directory "toggle"
  @screen_name "example/toggle"
  @definition %{
    directory: "toggle",
    family: :input,
    title: "Toggle Example",
    section: :inputs,
    story_text:
      "Meaningful Interaction Story: flip the toggle and confirm the preview stat reflects the normalized `switch` state without claiming a separate public toggle widget.",
    signal_text:
      "Canonical Signal Preview: change -> ExampleState.enabled -> canonical switch state and preview stat.",
    support_notice:
      "The sibling `toggle` directory is authored through the canonical `switch` widget, and its current state is surfaced through the preview stat rather than a fake device chrome.",
    preview_field: :enabled,
    seed_state: %{
      enabled: false,
      id: "state-toggle",
      status: "Directory parity preserved through canonical switch authoring."
    },
    subject_children: [],
    subject_action: nil,
    subject_binding: %{
      id: :toggle_value,
      target: "checked",
      field: :enabled,
      transform: %{}
    },
    subject_type: :switch,
    notes: "Preserves the sibling directory name while using the canonical switch widget.",
    preview_title: "Enabled state",
    subject_props: %{
      label: "Enable pager alerts",
      class: "ashui-example-toggle",
      checked: false
    }
  }
  @theme_css File.read!(Path.expand("../../assets/css/app.css", __DIR__))
  @default_runtime "live_ui"
  @supported_runtimes ["live_ui", "elm_ui", "desktop_ui"]
  @runtime_aliases %{
    "desktop" => "desktop_ui",
    "desktop_ui" => "desktop_ui",
    "elm" => "elm_ui",
    "elm_ui" => "elm_ui",
    "live" => "live_ui",
    "live-ui" => "live_ui",
    "live_ui" => "live_ui",
    "liveview" => "live_ui"
  }
  @runtime_descriptions %{
    "live_ui" =>
      "Default runtime: renders the live_ui surface inside the Phoenix LiveView example shell.",
    "elm_ui" =>
      "Alternate runtime: renders the canonical IUR through elm_ui and previews the generated document inside the Phoenix LiveView example shell.",
    "desktop_ui" =>
      "Alternate runtime: renders the canonical IUR to desktop_ui instructions and previews the generated payload inside the Phoenix LiveView example shell."
  }

  def app, do: :ash_ui_example_toggle
  def default_runtime, do: @default_runtime
  def definition, do: @definition

  def runtime_description(runtime),
    do: runtime |> normalize_runtime!() |> then(&Map.fetch!(@runtime_descriptions, &1))

  def supported_runtimes, do: @supported_runtimes
  def title, do: @definition.title
  def theme_css, do: @theme_css
  def screen_name, do: @screen_name

  def ui_storage do
    [
      domain: AshUIExamples.Toggle.UiStorageDomain,
      resources: [
        screen: AshUIExamples.Toggle.UiScreen,
        element: AshUIExamples.Toggle.UiElement,
        binding: AshUIExamples.Toggle.UiBinding
      ],
      repo: nil
    ]
  end

  def runtime_domains, do: [AshUIExamples.Toggle.RuntimeDomain]

  def current_user,
    do: %{active: true, id: "reviewer-toggle", name: "Example Reviewer", role: :admin}

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
      %{
        enabled: false,
        id: "state-toggle",
        status: "Directory parity preserved through canonical switch authoring."
      }
    )
  end

  def reset! do
    reset_resource!(AshUIExamples.Toggle.Runtime.ExampleState, AshUIExamples.Toggle.RuntimeDomain)
    reset_resource!(AshUIExamples.Toggle.UiBinding, AshUIExamples.Toggle.UiStorageDomain)
    reset_resource!(AshUIExamples.Toggle.UiElement, AshUIExamples.Toggle.UiStorageDomain)
    reset_resource!(AshUIExamples.Toggle.UiScreen, AshUIExamples.Toggle.UiStorageDomain)
    :ok
  end

  def seed!(opts \\ []) do
    actor = Keyword.get(opts, :actor, current_user())
    reset!()

    {:ok, _state} =
      Ash.create(
        AshUIExamples.Toggle.Runtime.ExampleState,
        seed_state(),
        domain: AshUIExamples.Toggle.RuntimeDomain,
        authorize?: false
      )

    {:ok, screen} =
      Authority.create(
        AshUIExamples.Toggle.Examples.ToggleScreen,
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

    socket =
      build_socket(%{
        current_user: seeded.actor,
        ash_ui_storage: seeded.ui_storage,
        ash_ui_domains: runtime_domains()
      })

    {:ok, mounted_socket} = Integration.mount_ui_screen(socket, seeded.screen_name, %{})
    {:ok, mounted_socket} = EventHandler.wire_handlers(mounted_socket)
    Map.put(seeded, :socket, mounted_socket)
  end

  def rendered_ui(assigns) do
    assigns
    |> rendered_runtime()
    |> then(& &1.content)
  end

  def normalize_runtime(nil), do: {:ok, @default_runtime}

  def normalize_runtime(runtime) when is_binary(runtime) do
    runtime =
      runtime
      |> String.trim()
      |> String.downcase()

    case Map.fetch(@runtime_aliases, runtime) do
      {:ok, canonical} -> {:ok, canonical}
      :error -> {:error, {:unsupported_runtime, runtime, @supported_runtimes}}
    end
  end

  def normalize_runtime!(runtime) do
    case normalize_runtime(runtime) do
      {:ok, canonical} ->
        canonical

      {:error, {:unsupported_runtime, value, supported}} ->
        raise ArgumentError,
              "unsupported runtime #{inspect(value)}; expected one of: #{Enum.join(supported, ", ")}"
    end
  end

  def rendered_runtime(assigns, runtime \\ default_runtime()) do
    runtime = normalize_runtime!(runtime)

    iur =
      assigns[:ash_ui_iur] ||
        Integration.hydrate_iur(assigns[:ash_ui_base_iur], assigns[:ash_ui_bindings] || %{})

    bindings = Map.values(assigns[:ash_ui_bindings] || %{})

    case runtime do
      "live_ui" ->
        {:ok, markup} =
          LiveUIAdapter.render(
            iur,
            bindings: bindings,
            event_prefix: "ash_ui",
            force_fallback: true
          )

        %{
          content: markup,
          description: runtime_description(runtime),
          mode: :live_fragment,
          runtime: runtime
        }

      "elm_ui" ->
        {:ok, html_document} = ElmUIAdapter.render(iur, title: title())

        %{
          content: html_document,
          description: runtime_description(runtime),
          mode: :html_document,
          runtime: runtime
        }

      "desktop_ui" ->
        {:ok, instructions} = DesktopUIAdapter.render(iur, window_title: title())

        %{
          content: Jason.encode!(instructions, pretty: true),
          description: runtime_description(runtime),
          mode: :desktop_instructions,
          runtime: runtime
        }
    end
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
        {Phoenix.PubSub, name: AshUIExamples.Toggle.PubSub},
        AshUIExamples.Toggle.Web.Endpoint
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
    end
  end

  defmodule RuntimeDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUIExamples.Toggle.Runtime.ExampleState)
    end
  end

  defmodule Runtime.ExampleState do
    use Ash.Resource, domain: AshUIExamples.Toggle.RuntimeDomain, data_layer: Ash.DataLayer.Ets

    ets do
      private?(true)
    end

    attributes do
      attribute :id, :string do
        primary_key?(true)
        allow_nil?(false)
      end

      attribute(:current_value, :string, default: "Ready")
      attribute(:display_value, :string, default: "Ready")
      attribute(:status, :string, default: "Mounted")
      attribute(:submitted_value, :string, default: "Not submitted")
      attribute(:selected_value, :string, default: "primary")
      attribute(:checked, :boolean, default: false)
      attribute(:enabled, :boolean, default: false)
      attribute(:notes, :string, default: "")
    end

    actions do
      defaults([:read, :destroy])

      create :create do
        primary?(true)

        accept([
          :id,
          :current_value,
          :display_value,
          :status,
          :submitted_value,
          :selected_value,
          :checked,
          :enabled,
          :notes
        ])
      end

      update :update do
        primary?(true)

        accept([
          :current_value,
          :display_value,
          :status,
          :submitted_value,
          :selected_value,
          :checked,
          :enabled,
          :notes
        ])
      end
    end
  end

  defmodule UiStorageDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUIExamples.Toggle.UiScreen)
      resource(AshUIExamples.Toggle.UiElement)
      resource(AshUIExamples.Toggle.UiBinding)
    end
  end

  defmodule UiScreen do
    use Ash.Resource,
      domain: AshUIExamples.Toggle.UiStorageDomain,
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
      has_many :elements, AshUIExamples.Toggle.UiElement do
        destination_attribute(:screen_id)
      end

      has_many :bindings, AshUIExamples.Toggle.UiBinding do
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
      domain: AshUIExamples.Toggle.UiStorageDomain,
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
      belongs_to :screen, AshUIExamples.Toggle.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      has_many :bindings, AshUIExamples.Toggle.UiBinding do
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
      domain: AshUIExamples.Toggle.UiStorageDomain,
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
      belongs_to :element, AshUIExamples.Toggle.UiElement do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      belongs_to :screen, AshUIExamples.Toggle.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end
    end

    actions do
      defaults([:read, :destroy])

      create :create do
        primary?(true)

        accept([
          :source,
          :target,
          :binding_type,
          :transform,
          :element_id,
          :screen_id,
          :metadata,
          :active,
          :version
        ])
      end

      update :update do
        primary?(true)

        accept([
          :source,
          :target,
          :binding_type,
          :transform,
          :element_id,
          :screen_id,
          :metadata,
          :active
        ])

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
      resource(AshUIExamples.Toggle.Examples.ToggleScreen)
      resource(AshUIExamples.Toggle.Examples.ToggleDemoPanelElement)
      resource(AshUIExamples.Toggle.Examples.ToggleSubjectElement)
      resource(AshUIExamples.Toggle.Examples.TogglePreviewElement)
      resource(AshUIExamples.Toggle.Examples.ToggleStoryTextElement)
      resource(AshUIExamples.Toggle.Examples.ToggleSignalTextElement)
      resource(AshUIExamples.Toggle.Examples.ToggleSupportNoticeElement)
    end
  end

  defmodule ExampleElementBase do
    defmacro __using__(_opts) do
      quote do
        use Ash.Resource,
          domain: AshUIExamples.Toggle.AuthoringDomain,
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

  defmodule Examples.ToggleDemoPanelElement do
    use AshUIExamples.Toggle.ExampleElementBase

    relationships do
      has_many :subjects, AshUIExamples.Toggle.Examples.ToggleSubjectElement do
        destination_attribute(:parent_id)
      end

      has_many :previews, AshUIExamples.Toggle.Examples.TogglePreviewElement do
        destination_attribute(:parent_id)
      end

      has_many :support_notices, AshUIExamples.Toggle.Examples.ToggleSupportNoticeElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :subjects do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :previews do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :support_notices do
        kind(:child)
        slot(:body)
        placement(:append)
        order(20)
      end
    end

    ui_element do
      type(:card)
      props(%{title: "Toggle Example", class: "ashui-example-panel"})
      metadata(%{id: "example-toggle-demo", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.ToggleSubjectElement do
    use AshUIExamples.Toggle.ExampleElementBase

    ui_element do
      type(:switch)
      props(%{label: "Enable pager alerts", class: "ashui-example-toggle", checked: false})
      metadata(%{id: "example-toggle-subject", section: "demo", slot: "body", position: 1})
    end

    ui_bindings do
      binding :toggle_value do
        source(%{resource: "ExampleState", field: :enabled, id: "state-toggle"})
        target("checked")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "subject", owner_signal: "change"})
      end
    end
  end

  defmodule Examples.TogglePreviewElement do
    use AshUIExamples.Toggle.ExampleElementBase

    ui_element do
      type(:stat)
      props(%{title: "Enabled state", value: false})
      variants([:primary])
      metadata(%{id: "example-toggle-preview", section: "demo", slot: "body", position: 2})
    end

    ui_bindings do
      binding :preview_value do
        source(%{resource: "ExampleState", field: :enabled, id: "state-toggle"})
        target("value")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "preview"})
      end
    end
  end

  defmodule Examples.ToggleStoryTextElement do
    use AshUIExamples.Toggle.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Meaningful Interaction Story: flip the toggle and confirm the preview stat reflects the normalized `switch` state without claiming a separate public toggle widget.",
        class: "ashui-example-code-surface"
      })

      metadata(%{id: "example-toggle-story", section: "story", slot: "body", position: 10})
    end
  end

  defmodule Examples.ToggleSignalTextElement do
    use AshUIExamples.Toggle.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Canonical Signal Preview: change -> ExampleState.enabled -> canonical switch state and preview stat.",
        class: "ashui-example-code-surface"
      })

      metadata(%{
        id: "example-toggle-signal-preview",
        section: "signal_preview",
        slot: "body",
        position: 20
      })
    end
  end

  defmodule Examples.ToggleSupportNoticeElement do
    use AshUIExamples.Toggle.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "The sibling `toggle` directory is authored through the canonical `switch` widget, and its current state is surfaced through the preview stat rather than a fake device chrome.",
        class: "ashui-example-focus-ring"
      })

      metadata(%{id: "example-toggle-support-note", section: "demo", slot: "body", position: 3})
    end
  end

  defmodule Examples.ToggleScreen do
    use Ash.Resource,
      domain: AshUIExamples.Toggle.AuthoringDomain,
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
      has_many :demo_panels, AshUIExamples.Toggle.Examples.ToggleDemoPanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts, AshUIExamples.Toggle.Examples.ToggleStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts, AshUIExamples.Toggle.Examples.ToggleSignalTextElement do
        destination_attribute(:screen_id)
      end
    end

    ui_relationships do
      relationship :demo_panels do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :story_texts do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :signal_texts do
        kind(:child)
        slot(:body)
        placement(:append)
        order(20)
      end
    end

    ui_screen do
      layout(:column)
      route("/")

      metadata(%{
        title: "Toggle Example",
        example_directory: "toggle",
        shell_id: "example-toggle-shell"
      })
    end
  end

  defmodule ExampleSeeds do
    def seed!(opts \\ []), do: AshUIExamples.Toggle.seed!(opts)
    def reset!, do: AshUIExamples.Toggle.reset!()
  end

  defmodule Web.Router do
    use Phoenix.Router
    import Phoenix.LiveView.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:protect_from_forgery)
      plug(:put_secure_browser_headers)
    end

    scope "/", AshUIExamples.Toggle.Web do
      pipe_through(:browser)
      live("/", ExampleLive)
    end
  end

  defmodule Web.Endpoint do
    use Phoenix.Endpoint, otp_app: :ash_ui_example_toggle

    @session_options [
      store: :cookie,
      key: "_ash_ui_example_key",
      signing_salt: "ashuiph18"
    ]

    socket("/live", Phoenix.LiveView.Socket,
      websocket: [connect_info: [session: @session_options]]
    )

    plug(Plug.RequestId)
    plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])
    plug(Plug.Session, @session_options)
    plug(AshUIExamples.Toggle.Web.Router)
  end

  defmodule Web.Components.ExampleShell do
    use Phoenix.Component

    attr(:title, :string, required: true)
    attr(:directory, :string, required: true)
    attr(:summary, :string, required: true)
    attr(:theme_css, :string, required: true)
    slot(:inner_block, required: true)

    def example_shell(assigns) do
      ~H"""
      <style><%= Phoenix.HTML.raw(@theme_css) %></style>
      <main id={"example-#{@directory}-shell"} class="ashui-example-shell">
        <header class="ashui-example-shell-header">
          <p class="ashui-example-shell-kicker">Ash UI Example</p>
          <h1 class="ashui-example-shell-title"><%= @title %></h1>
          <p class="ashui-example-shell-summary"><%= @summary %></p>
        </header>
        <section class="ashui-example-live-surface">
          <%= render_slot(@inner_block) %>
        </section>
      </main>
      """
    end
  end

  defmodule Web.ExampleLive do
    use Phoenix.LiveView

    alias AshUIExamples.Toggle.Web.Components.ExampleShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      _ = AshUIExamples.Toggle.seed!()
      example_runtime = runtime_from_params(params)

      socket =
        socket
        |> Phoenix.Component.assign(:current_user, AshUIExamples.Toggle.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUIExamples.Toggle.ui_storage())
        |> Phoenix.Component.assign(:ash_ui_domains, AshUIExamples.Toggle.runtime_domains())
        |> Phoenix.Component.assign(:page_title, "Toggle Example")
        |> Phoenix.Component.assign(:example_directory, "toggle")
        |> Phoenix.Component.assign(:theme_css, AshUIExamples.Toggle.theme_css())
        |> Phoenix.Component.assign(:example_runtime, example_runtime)
        |> Phoenix.Component.assign(
          :supported_runtimes,
          AshUIExamples.Toggle.supported_runtimes()
        )

      with {:ok, socket} <- Integration.mount_ui_screen(socket, "example/toggle", params),
           {:ok, socket} <- EventHandler.wire_handlers(socket) do
        {:ok, refresh_rendered_ui(socket)}
      else
        {:error, reason} ->
          {:ok,
           Phoenix.Component.assign(socket, :rendered_ui, "Mount failed: #{inspect(reason)}")}
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
      assigns =
        assigns
        |> Phoenix.Component.assign_new(:supported_runtimes, fn ->
          AshUIExamples.Toggle.supported_runtimes()
        end)
        |> Phoenix.Component.assign_new(:example_runtime, fn ->
          AshUIExamples.Toggle.default_runtime()
        end)
        |> Phoenix.Component.assign_new(:rendered_runtime, fn ->
          %{
            content: assigns[:rendered_ui] || "",
            description:
              AshUIExamples.Toggle.runtime_description(AshUIExamples.Toggle.default_runtime()),
            mode: :live_fragment,
            runtime: AshUIExamples.Toggle.default_runtime()
          }
        end)

      ~H"""
      <ExampleShell.example_shell
        title={@page_title}
        directory={@example_directory}
        summary={"Meaningful Interaction Story: flip the toggle and confirm the preview stat reflects the normalized `switch` state without claiming a separate public toggle widget."}
        theme_css={@theme_css}
      >
        <section class="ashui-example-runtime-panel" id={"example-#{@example_directory}-runtime"}>
          <div class="ashui-example-runtime-copy">
            <h2 class="ashui-example-runtime-title">
              Runtime preview: <%= @rendered_runtime.runtime %>
            </h2>
            <p class="ashui-example-runtime-copy"><%= @rendered_runtime.description %></p>
          </div>
          <div class="ashui-example-runtime-actions">
            <%= for runtime <- @supported_runtimes do %>
              <code class="ashui-example-runtime-command">mix example.start <%= runtime %></code>
            <% end %>
          </div>
        </section>
        <section class="ashui-example-runtime-view">
          <%= case @rendered_runtime.mode do %>
            <% :html_document -> %>
              <iframe
                class="ashui-example-runtime-frame"
                sandbox="allow-same-origin"
                srcdoc={@rendered_runtime.content}
                title={"#{@example_directory}-#{@rendered_runtime.runtime}"}
              />
            <% :desktop_instructions -> %>
              <pre class="ashui-example-runtime-pre"><%= @rendered_runtime.content %></pre>
            <% :live_fragment -> %>
              <%= Phoenix.HTML.raw(@rendered_runtime.content) %>
          <% end %>
        </section>
      </ExampleShell.example_shell>
      """
    end

    defp refresh_rendered_ui(socket) do
      rendered_runtime =
        AshUIExamples.Toggle.rendered_runtime(
          socket.assigns,
          socket.assigns[:example_runtime] || AshUIExamples.Toggle.default_runtime()
        )

      socket
      |> Phoenix.Component.assign(:rendered_runtime, rendered_runtime)
      |> Phoenix.Component.assign(:rendered_ui, rendered_runtime.content)
    end

    defp runtime_from_params(params) do
      params["runtime"]
      |> fallback_runtime()
      |> AshUIExamples.Toggle.normalize_runtime!()
    end

    defp fallback_runtime(nil), do: System.get_env("ASH_UI_EXAMPLE_RUNTIME")
    defp fallback_runtime(runtime), do: runtime
  end
end
