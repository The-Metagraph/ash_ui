defmodule AshUITutorials.ProjectShell do
  @moduledoc """
  Chapter 1 checkpoint app for the Operations Control Center tutorial.
  """

  use Phoenix.Component

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.{DesktopUIAdapter, ElmUIAdapter, LiveUIAdapter}
  alias AshUI.Resource.Authority
  alias AshUI.Tutorials.Phase23, as: TutorialBaseline

  @app :ash_ui_tutorial_project_shell
  @screen_name "tutorial/project-shell/home"
  @title "Operations Control Center - Project Shell"
  @summary "Build the first shared shell and mount the tutorial dashboard from authoritative screen and element resources."
  @story_text "Meaningful Interaction Story: review the seeded shell, acknowledge the bootstrap checkpoint, and confirm the dashboard copy updates through the runtime state resource instead of host-only markup."
  @signal_text "Canonical Signal Preview: button click -> WorkspaceState.update(status, current_value, next_step) -> hydrated dashboard text inside the shared Operations Control Center shell."
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
      "Default runtime: renders the live_ui fragment through the tutorial's Phoenix LiveView host.",
    "elm_ui" =>
      "Alternate runtime: renders the canonical IUR through elm_ui and previews the generated document inside the same host shell.",
    "desktop_ui" =>
      "Alternate runtime: renders the canonical IUR to desktop_ui instructions and previews the generated payload inside the same host shell."
  }

  def app, do: @app
  def title, do: @title
  def summary, do: @summary
  def story_text, do: @story_text
  def signal_text, do: @signal_text
  def theme_css, do: @theme_css
  def default_runtime, do: @default_runtime
  def supported_runtimes, do: @supported_runtimes
  def screen_name, do: @screen_name

  def runtime_description(runtime),
    do: runtime |> normalize_runtime!() |> then(&Map.fetch!(@runtime_descriptions, &1))

  def ui_storage do
    [
      domain: AshUITutorials.ProjectShell.UiStorageDomain,
      resources: [
        screen: AshUITutorials.ProjectShell.UiScreen,
        element: AshUITutorials.ProjectShell.UiElement,
        binding: AshUITutorials.ProjectShell.UiBinding
      ],
      repo: nil
    ]
  end

  def runtime_domains, do: [AshUITutorials.ProjectShell.RuntimeDomain]

  def actor_profile(role) do
    Enum.find(TutorialBaseline.actor_profiles(), &(&1.role == role))
  end

  def current_user, do: actor_profile(:admin)

  def seed_state do
    fixtures = TutorialBaseline.seed_fixtures()

    %{
      id: "tutorial-shell-state",
      status: "Dashboard shell seeded and ready for Chapter 1 review.",
      current_value: "home dashboard",
      hero_summary:
        "The Operations Control Center opens on a high-signal home shell before later chapters add multi-screen workspaces.",
      next_step: "Next checkpoint: services and incidents workspace.",
      services_count: Integer.to_string(length(fixtures.services)),
      incidents_count: Integer.to_string(length(fixtures.incidents)),
      on_call_name: actor_profile(:on_call_operator).name
    }
  end

  def reset! do
    reset_resource!(AshUITutorials.ProjectShell.Runtime.WorkspaceState, AshUITutorials.ProjectShell.RuntimeDomain)
    reset_resource!(AshUITutorials.ProjectShell.UiBinding, AshUITutorials.ProjectShell.UiStorageDomain)
    reset_resource!(AshUITutorials.ProjectShell.UiElement, AshUITutorials.ProjectShell.UiStorageDomain)
    reset_resource!(AshUITutorials.ProjectShell.UiScreen, AshUITutorials.ProjectShell.UiStorageDomain)
    :ok
  end

  def seed!(opts \\ []) do
    actor = Keyword.get(opts, :actor, current_user())
    reset!()

    {:ok, _state} =
      Ash.create(
        AshUITutorials.ProjectShell.Runtime.WorkspaceState,
        seed_state(),
        domain: AshUITutorials.ProjectShell.RuntimeDomain,
        authorize?: false
      )

    {:ok, screen} =
      Authority.create(
        AshUITutorials.ProjectShell.Examples.HomeScreen,
        actor: actor,
        name: @screen_name,
        ui_storage: ui_storage()
      )

    %{actor: actor, screen: screen, screen_name: @screen_name, ui_storage: ui_storage()}
  end

  def build_socket(extra_assigns \\ %{}) do
    %Phoenix.LiveView.Socket{
      assigns:
        Map.merge(
          %{
            __changed__: %{},
            flash: %{},
            current_user: current_user(),
            ash_ui_storage: ui_storage(),
            ash_ui_domains: runtime_domains()
          },
          extra_assigns
        )
    }
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

  def normalize_runtime(nil), do: {:ok, @default_runtime}

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

        %{content: markup, description: runtime_description(runtime), mode: :live_fragment, runtime: runtime}

      "elm_ui" ->
        {:ok, html_document} = ElmUIAdapter.render(iur, title: title())
        %{content: html_document, description: runtime_description(runtime), mode: :html_document, runtime: runtime}

      "desktop_ui" ->
        {:ok, instructions} = DesktopUIAdapter.render(iur, window_title: title())
        %{content: Jason.encode!(instructions, pretty: true), description: runtime_description(runtime), mode: :desktop_instructions, runtime: runtime}
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
        {Phoenix.PubSub, name: AshUITutorials.ProjectShell.PubSub},
        AshUITutorials.ProjectShell.Web.Endpoint
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
    end
  end

  defmodule RuntimeDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUITutorials.ProjectShell.Runtime.WorkspaceState)
    end
  end

  defmodule Runtime.WorkspaceState do
    use Ash.Resource,
      domain: AshUITutorials.ProjectShell.RuntimeDomain,
      authorizers: [Ash.Policy.Authorizer],
      data_layer: Ash.DataLayer.Ets

    ets do
      private?(true)
    end

    attributes do
      attribute :id, :string do
        primary_key?(true)
        allow_nil?(false)
      end

      attribute :status, :string, default: "Dashboard shell seeded and ready for Chapter 1 review."
      attribute :current_value, :string, default: "home dashboard"
      attribute :hero_summary, :string, default: ""
      attribute :next_step, :string, default: ""
      attribute :services_count, :string, default: "0"
      attribute :incidents_count, :string, default: "0"
      attribute :on_call_name, :string, default: ""
    end

    actions do
      defaults([:read, :destroy])

      create :create do
        primary?(true)
        accept([:id, :status, :current_value, :hero_summary, :next_step, :services_count, :incidents_count, :on_call_name])
      end

      update :update do
        primary?(true)
        accept([:status, :current_value, :hero_summary, :next_step, :services_count, :incidents_count, :on_call_name])
      end
    end

    policies do
      bypass actor_attribute_equals(:role, :admin) do
        authorize_if(always())
      end

      policy action_type(:read) do
        authorize_if(actor_attribute_equals(:active, true))
      end

      policy action([:create, :update, :destroy]) do
        authorize_if(actor_attribute_equals(:role, :on_call_operator))
      end
    end
  end

  defmodule UiStorageDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUITutorials.ProjectShell.UiScreen)
      resource(AshUITutorials.ProjectShell.UiElement)
      resource(AshUITutorials.ProjectShell.UiBinding)
    end
  end

  defmodule UiScreen do
    use Ash.Resource,
      domain: AshUITutorials.ProjectShell.UiStorageDomain,
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
      has_many :elements, AshUITutorials.ProjectShell.UiElement do
        destination_attribute(:screen_id)
      end

      has_many :bindings, AshUITutorials.ProjectShell.UiBinding do
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
      domain: AshUITutorials.ProjectShell.UiStorageDomain,
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
      belongs_to :screen, AshUITutorials.ProjectShell.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      has_many :bindings, AshUITutorials.ProjectShell.UiBinding do
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
      domain: AshUITutorials.ProjectShell.UiStorageDomain,
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
      belongs_to :element, AshUITutorials.ProjectShell.UiElement do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      belongs_to :screen, AshUITutorials.ProjectShell.UiScreen do
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
      resource(AshUITutorials.ProjectShell.Examples.HomeScreen)
      resource(AshUITutorials.ProjectShell.Examples.HomePanelElement)
      resource(AshUITutorials.ProjectShell.Examples.HomeHeaderColumnElement)
      resource(AshUITutorials.ProjectShell.Examples.HomeTitleRowElement)
      resource(AshUITutorials.ProjectShell.Examples.HomeKickerTextElement)
      resource(AshUITutorials.ProjectShell.Examples.HomeTitleIconElement)
      resource(AshUITutorials.ProjectShell.Examples.HomeTitleTextElement)
      resource(AshUITutorials.ProjectShell.Examples.HomeSummaryTextElement)
      resource(AshUITutorials.ProjectShell.Examples.HomeStatusLabelElement)
      resource(AshUITutorials.ProjectShell.Examples.HomeDividerElement)
      resource(AshUITutorials.ProjectShell.Examples.HomeActionRowElement)
      resource(AshUITutorials.ProjectShell.Examples.HomeReviewButtonElement)
      resource(AshUITutorials.ProjectShell.Examples.HomeDocsLinkElement)
      resource(AshUITutorials.ProjectShell.Examples.HomeActionSpacerElement)
      resource(AshUITutorials.ProjectShell.Examples.HomeSummaryGridElement)
      resource(AshUITutorials.ProjectShell.Examples.HomeServicesCardElement)
      resource(AshUITutorials.ProjectShell.Examples.HomeServicesLabelElement)
      resource(AshUITutorials.ProjectShell.Examples.HomeServicesValueElement)
      resource(AshUITutorials.ProjectShell.Examples.HomeIncidentsCardElement)
      resource(AshUITutorials.ProjectShell.Examples.HomeIncidentsLabelElement)
      resource(AshUITutorials.ProjectShell.Examples.HomeIncidentsValueElement)
      resource(AshUITutorials.ProjectShell.Examples.HomeOnCallCardElement)
      resource(AshUITutorials.ProjectShell.Examples.HomeOnCallLabelElement)
      resource(AshUITutorials.ProjectShell.Examples.HomeOnCallValueElement)
      resource(AshUITutorials.ProjectShell.Examples.HomeFooterRowElement)
      resource(AshUITutorials.ProjectShell.Examples.HomeSignalIconElement)
      resource(AshUITutorials.ProjectShell.Examples.HomeCurrentValueElement)
      resource(AshUITutorials.ProjectShell.Examples.HomeNextStepElement)
      resource(AshUITutorials.ProjectShell.Examples.HomeStoryTextElement)
      resource(AshUITutorials.ProjectShell.Examples.HomeSignalTextElement)
    end
  end

  defmodule ExampleElementBase do
    defmacro __using__(_opts) do
      quote do
        use Ash.Resource,
          domain: AshUITutorials.ProjectShell.AuthoringDomain,
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

  defmodule Examples.HomePanelElement do
    use AshUITutorials.ProjectShell.ExampleElementBase

    relationships do
      has_many :header_columns, AshUITutorials.ProjectShell.Examples.HomeHeaderColumnElement do
        destination_attribute(:parent_id)
      end

      has_many :action_rows, AshUITutorials.ProjectShell.Examples.HomeActionRowElement do
        destination_attribute(:parent_id)
      end

      has_many :summary_grids, AshUITutorials.ProjectShell.Examples.HomeSummaryGridElement do
        destination_attribute(:parent_id)
      end

      has_many :footer_rows, AshUITutorials.ProjectShell.Examples.HomeFooterRowElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :header_columns do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :action_rows do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :summary_grids do
        kind(:child)
        slot(:body)
        placement(:append)
        order(20)
      end

      relationship :footer_rows do
        kind(:child)
        slot(:footer)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:card)
      props(%{title: "Chapter 1 dashboard", class: "ashui-example-panel ashui-tutorial-hero-panel"})
      metadata(%{id: "tutorial-shell-panel", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.HomeHeaderColumnElement do
    use AshUITutorials.ProjectShell.ExampleElementBase

    relationships do
      has_many :kicker_texts, AshUITutorials.ProjectShell.Examples.HomeKickerTextElement do
        destination_attribute(:parent_id)
      end

      has_many :title_rows, AshUITutorials.ProjectShell.Examples.HomeTitleRowElement do
        destination_attribute(:parent_id)
      end

      has_many :summary_texts, AshUITutorials.ProjectShell.Examples.HomeSummaryTextElement do
        destination_attribute(:parent_id)
      end

      has_many :status_labels, AshUITutorials.ProjectShell.Examples.HomeStatusLabelElement do
        destination_attribute(:parent_id)
      end

      has_many :divider_elements, AshUITutorials.ProjectShell.Examples.HomeDividerElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :kicker_texts do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :title_rows do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :summary_texts do
        kind(:child)
        slot(:body)
        placement(:append)
        order(20)
      end

      relationship :status_labels do
        kind(:child)
        slot(:body)
        placement(:append)
        order(30)
      end

      relationship :divider_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(40)
      end
    end

    ui_element do
      type(:column)
      props(%{class: "ashui-tutorial-hero-column", spacing: 14})
      metadata(%{id: "tutorial-shell-header-column", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.HomeTitleRowElement do
    use AshUITutorials.ProjectShell.ExampleElementBase

    relationships do
      has_many :title_icon_elements, AshUITutorials.ProjectShell.Examples.HomeTitleIconElement do
        destination_attribute(:parent_id)
      end

      has_many :title_text_elements, AshUITutorials.ProjectShell.Examples.HomeTitleTextElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :title_icon_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :title_text_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end
    end

    ui_element do
      type(:row)
      props(%{class: "ashui-tutorial-title-row", spacing: 12})
      metadata(%{id: "tutorial-shell-title-row", section: "demo", slot: "body", position: 10})
    end
  end

  defmodule Examples.HomeKickerTextElement do
    use AshUITutorials.ProjectShell.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "Chapter 1 checkpoint", class: "ashui-tutorial-shell-kicker"})
      metadata(%{id: "tutorial-shell-kicker", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.HomeTitleIconElement do
    use AshUITutorials.ProjectShell.ExampleElementBase

    ui_element do
      type(:icon)
      props(%{name: "spark", label: "Operations Control Center", class: "ashui-tutorial-muted-copy"})
      metadata(%{id: "tutorial-shell-title-icon", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.HomeTitleTextElement do
    use AshUITutorials.ProjectShell.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "Operations Control Center", class: "ashui-tutorial-shell-title"})
      metadata(%{id: "tutorial-shell-title", section: "demo", slot: "body", position: 10})
    end
  end

  defmodule Examples.HomeSummaryTextElement do
    use AshUITutorials.ProjectShell.ExampleElementBase

    ui_element do
      type(:text)
      props(%{
        content:
          "Build the first shared shell and mount the tutorial dashboard from authoritative screen and element resources.",
        class: "ashui-tutorial-shell-summary"
      })
      metadata(%{id: "tutorial-shell-summary", section: "demo", slot: "body", position: 20})
    end

    ui_bindings do
      binding :hero_summary do
        source(%{resource: "WorkspaceState", field: :hero_summary, id: "tutorial-shell-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "hero_summary"})
      end
    end
  end

  defmodule Examples.HomeStatusLabelElement do
    use AshUITutorials.ProjectShell.ExampleElementBase

    ui_element do
      type(:label)
      props(%{content: "Dashboard shell seeded and ready for Chapter 1 review.", class: "ashui-tutorial-status-label"})
      metadata(%{id: "tutorial-shell-status", section: "demo", slot: "body", position: 30})
    end

    ui_bindings do
      binding :status_label do
        source(%{resource: "WorkspaceState", field: :status, id: "tutorial-shell-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "status"})
      end
    end
  end

  defmodule Examples.HomeDividerElement do
    use AshUITutorials.ProjectShell.ExampleElementBase

    ui_element do
      type(:divider)
      props(%{class: "ashui-tutorial-divider"})
      metadata(%{id: "tutorial-shell-divider", section: "demo", slot: "body", position: 40})
    end
  end

  defmodule Examples.HomeActionRowElement do
    use AshUITutorials.ProjectShell.ExampleElementBase

    relationships do
      has_many :review_buttons, AshUITutorials.ProjectShell.Examples.HomeReviewButtonElement do
        destination_attribute(:parent_id)
      end

      has_many :docs_links, AshUITutorials.ProjectShell.Examples.HomeDocsLinkElement do
        destination_attribute(:parent_id)
      end

      has_many :action_spacers, AshUITutorials.ProjectShell.Examples.HomeActionSpacerElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :review_buttons do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :docs_links do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :action_spacers do
        kind(:child)
        slot(:body)
        placement(:append)
        order(20)
      end
    end

    ui_element do
      type(:row)
      props(%{class: "ashui-tutorial-action-row", spacing: 12})
      metadata(%{id: "tutorial-shell-actions", section: "demo", slot: "body", position: 10})
    end
  end

  defmodule Examples.HomeReviewButtonElement do
    use AshUITutorials.ProjectShell.ExampleElementBase

    ui_element do
      type(:button)
      props(%{label: "Acknowledge shell review", class: "ashui-example-primary-cta", variant: "primary"})
      metadata(%{id: "tutorial-shell-review-button", section: "demo", slot: "body", position: 0})
    end

    ui_actions do
      action :acknowledge_shell_review do
        signal(:click)
        source(%{id: "tutorial-shell-state", resource: "WorkspaceState", action: "update"})
        target("submit")

        transform(%{
          params: %{
            status: %{"from" => "static", "value" => "Shell review acknowledged. The dashboard is ready to grow into real workspaces."},
            current_value: %{"from" => "static", "value" => "shell review complete"},
            next_step: %{"from" => "static", "value" => "Next checkpoint: map services and incidents into separate operator workspaces."}
          }
        })

        metadata(%{intent: "acknowledge_shell", success_message: "Shell checkpoint reviewed"})
      end
    end
  end

  defmodule Examples.HomeDocsLinkElement do
    use AshUITutorials.ProjectShell.ExampleElementBase

    ui_element do
      type(:"custom:link")
      props(%{
        href: "https://www.ash-hq.org/",
        label: "Review Ash HQ baseline",
        class: "ashui-example-secondary-cta"
      })

      metadata(%{id: "tutorial-shell-docs-link", section: "demo", slot: "body", position: 10})
    end
  end

  defmodule Examples.HomeActionSpacerElement do
    use AshUITutorials.ProjectShell.ExampleElementBase

    ui_element do
      type(:spacer)
      props(%{size: 12})
      metadata(%{id: "tutorial-shell-action-spacer", section: "demo", slot: "body", position: 20})
    end
  end

  defmodule Examples.HomeSummaryGridElement do
    use AshUITutorials.ProjectShell.ExampleElementBase

    relationships do
      has_many :services_cards, AshUITutorials.ProjectShell.Examples.HomeServicesCardElement do
        destination_attribute(:parent_id)
      end

      has_many :incidents_cards, AshUITutorials.ProjectShell.Examples.HomeIncidentsCardElement do
        destination_attribute(:parent_id)
      end

      has_many :on_call_cards, AshUITutorials.ProjectShell.Examples.HomeOnCallCardElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :services_cards do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :incidents_cards do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :on_call_cards do
        kind(:child)
        slot(:body)
        placement(:append)
        order(20)
      end
    end

    ui_element do
      type(:grid)
      props(%{columns: 3, spacing: 16, class: "ashui-tutorial-summary-grid"})
      metadata(%{id: "tutorial-shell-summary-grid", section: "demo", slot: "body", position: 20})
    end
  end

  defmodule Examples.HomeServicesCardElement do
    use AshUITutorials.ProjectShell.ExampleElementBase

    relationships do
      has_many :services_labels, AshUITutorials.ProjectShell.Examples.HomeServicesLabelElement do
        destination_attribute(:parent_id)
      end

      has_many :services_values, AshUITutorials.ProjectShell.Examples.HomeServicesValueElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :services_labels do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :services_values do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end
    end

    ui_element do
      type(:card)
      props(%{class: "ashui-tutorial-stat-card"})
      metadata(%{id: "tutorial-shell-services-card", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.HomeServicesLabelElement do
    use AshUITutorials.ProjectShell.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "Tracked services", class: "ashui-tutorial-stat-label"})
      metadata(%{id: "tutorial-shell-services-label", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.HomeServicesValueElement do
    use AshUITutorials.ProjectShell.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "0", class: "ashui-tutorial-stat-value"})
      metadata(%{id: "tutorial-shell-services-value", section: "demo", slot: "body", position: 10})
    end

    ui_bindings do
      binding :services_count do
        source(%{resource: "WorkspaceState", field: :services_count, id: "tutorial-shell-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "services_count"})
      end
    end
  end

  defmodule Examples.HomeIncidentsCardElement do
    use AshUITutorials.ProjectShell.ExampleElementBase

    relationships do
      has_many :incidents_labels, AshUITutorials.ProjectShell.Examples.HomeIncidentsLabelElement do
        destination_attribute(:parent_id)
      end

      has_many :incidents_values, AshUITutorials.ProjectShell.Examples.HomeIncidentsValueElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :incidents_labels do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :incidents_values do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end
    end

    ui_element do
      type(:card)
      props(%{class: "ashui-tutorial-stat-card"})
      metadata(%{id: "tutorial-shell-incidents-card", section: "demo", slot: "body", position: 10})
    end
  end

  defmodule Examples.HomeIncidentsLabelElement do
    use AshUITutorials.ProjectShell.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "Open incidents", class: "ashui-tutorial-stat-label"})
      metadata(%{id: "tutorial-shell-incidents-label", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.HomeIncidentsValueElement do
    use AshUITutorials.ProjectShell.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "0", class: "ashui-tutorial-stat-value"})
      metadata(%{id: "tutorial-shell-incidents-value", section: "demo", slot: "body", position: 10})
    end

    ui_bindings do
      binding :incidents_count do
        source(%{resource: "WorkspaceState", field: :incidents_count, id: "tutorial-shell-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "incidents_count"})
      end
    end
  end

  defmodule Examples.HomeOnCallCardElement do
    use AshUITutorials.ProjectShell.ExampleElementBase

    relationships do
      has_many :on_call_labels, AshUITutorials.ProjectShell.Examples.HomeOnCallLabelElement do
        destination_attribute(:parent_id)
      end

      has_many :on_call_values, AshUITutorials.ProjectShell.Examples.HomeOnCallValueElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :on_call_labels do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :on_call_values do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end
    end

    ui_element do
      type(:card)
      props(%{class: "ashui-tutorial-stat-card"})
      metadata(%{id: "tutorial-shell-on-call-card", section: "demo", slot: "body", position: 20})
    end
  end

  defmodule Examples.HomeOnCallLabelElement do
    use AshUITutorials.ProjectShell.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "Primary on-call", class: "ashui-tutorial-stat-label"})
      metadata(%{id: "tutorial-shell-on-call-label", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.HomeOnCallValueElement do
    use AshUITutorials.ProjectShell.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "", class: "ashui-tutorial-stat-value"})
      metadata(%{id: "tutorial-shell-on-call-value", section: "demo", slot: "body", position: 10})
    end

    ui_bindings do
      binding :on_call_name do
        source(%{resource: "WorkspaceState", field: :on_call_name, id: "tutorial-shell-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "on_call_name"})
      end
    end
  end

  defmodule Examples.HomeFooterRowElement do
    use AshUITutorials.ProjectShell.ExampleElementBase

    relationships do
      has_many :signal_icon_elements, AshUITutorials.ProjectShell.Examples.HomeSignalIconElement do
        destination_attribute(:parent_id)
      end

      has_many :current_value_elements, AshUITutorials.ProjectShell.Examples.HomeCurrentValueElement do
        destination_attribute(:parent_id)
      end

      has_many :next_step_elements, AshUITutorials.ProjectShell.Examples.HomeNextStepElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :signal_icon_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :current_value_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end

      relationship :next_step_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(20)
      end
    end

    ui_element do
      type(:row)
      props(%{class: "ashui-tutorial-footer-row", spacing: 12})
      metadata(%{id: "tutorial-shell-footer-row", section: "demo", slot: "footer", position: 0})
    end
  end

  defmodule Examples.HomeSignalIconElement do
    use AshUITutorials.ProjectShell.ExampleElementBase

    ui_element do
      type(:icon)
      props(%{name: "spark", label: "Current stage", class: "ashui-tutorial-muted-copy"})
      metadata(%{id: "tutorial-shell-signal-icon", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.HomeCurrentValueElement do
    use AshUITutorials.ProjectShell.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "home dashboard", class: "ashui-tutorial-detail-text"})
      metadata(%{id: "tutorial-shell-current-value", section: "demo", slot: "body", position: 10})
    end

    ui_bindings do
      binding :current_value do
        source(%{resource: "WorkspaceState", field: :current_value, id: "tutorial-shell-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "current_value"})
      end
    end
  end

  defmodule Examples.HomeNextStepElement do
    use AshUITutorials.ProjectShell.ExampleElementBase

    ui_element do
      type(:text)
      props(%{content: "Next checkpoint: services and incidents workspace.", class: "ashui-tutorial-muted-copy"})
      metadata(%{id: "tutorial-shell-next-step", section: "demo", slot: "body", position: 20})
    end

    ui_bindings do
      binding :next_step do
        source(%{resource: "WorkspaceState", field: :next_step, id: "tutorial-shell-state"})
        target("content")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "next_step"})
      end
    end
  end

  defmodule Examples.HomeStoryTextElement do
    use AshUITutorials.ProjectShell.ExampleElementBase

    ui_element do
      type(:text)
      props(%{
        content:
          "Meaningful Interaction Story: review the seeded shell, acknowledge the bootstrap checkpoint, and confirm the dashboard copy updates through the runtime state resource instead of host-only markup.",
        class: "ashui-example-code-surface"
      })
      metadata(%{id: "tutorial-shell-story", section: "story", slot: "body", position: 10})
    end
  end

  defmodule Examples.HomeSignalTextElement do
    use AshUITutorials.ProjectShell.ExampleElementBase

    ui_element do
      type(:text)
      props(%{
        content:
          "Canonical Signal Preview: button click -> WorkspaceState.update(status, current_value, next_step) -> hydrated dashboard text inside the shared Operations Control Center shell.",
        class: "ashui-example-code-surface"
      })
      metadata(%{id: "tutorial-shell-signal", section: "signal_preview", slot: "body", position: 20})
    end
  end

  defmodule Examples.HomeScreen do
    use Ash.Resource,
      domain: AshUITutorials.ProjectShell.AuthoringDomain,
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
      has_many :home_panels, AshUITutorials.ProjectShell.Examples.HomePanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts, AshUITutorials.ProjectShell.Examples.HomeStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts, AshUITutorials.ProjectShell.Examples.HomeSignalTextElement do
        destination_attribute(:screen_id)
      end
    end

    ui_relationships do
      relationship :home_panels do
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
        title: "Operations Control Center - Project Shell",
        tutorial_directory: "01-project-shell",
        shell_id: "tutorial-project-shell-shell"
      })
    end
  end

  defmodule ExampleSeeds do
    def seed!(opts \\ []), do: AshUITutorials.ProjectShell.seed!(opts)
    def reset!, do: AshUITutorials.ProjectShell.reset!()
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

    scope "/", AshUITutorials.ProjectShell.Web do
      pipe_through(:browser)
      live("/", HomeLive)
    end
  end

  defmodule Web.Endpoint do
    use Phoenix.Endpoint, otp_app: :ash_ui_tutorial_project_shell

    @session_options [
      store: :cookie,
      key: "_ash_ui_tutorial_project_shell_key",
      signing_salt: "ashuitut23a"
    ]

    socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

    plug(Plug.RequestId)
    plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])
    plug(Plug.Session, @session_options)
    plug(AshUITutorials.ProjectShell.Web.Router)
  end

  defmodule Web.Components.TutorialShell do
    use Phoenix.Component

    attr(:title, :string, required: true)
    attr(:summary, :string, required: true)
    attr(:theme_css, :string, required: true)
    slot(:inner_block, required: true)

    def tutorial_shell(assigns) do
      ~H"""
      <style><%= Phoenix.HTML.raw(@theme_css) %></style>
      <main id="tutorial-project-shell-shell" class="ashui-example-shell">
        <header class="ashui-tutorial-shell-header">
          <p class="ashui-tutorial-shell-kicker">Ash UI Tutorial</p>
          <h1 class="ashui-tutorial-shell-title"><%= @title %></h1>
          <p class="ashui-tutorial-shell-summary"><%= @summary %></p>
        </header>
        <section class="ashui-tutorial-live-surface">
          <%= render_slot(@inner_block) %>
        </section>
      </main>
      """
    end
  end

  defmodule Web.HomeLive do
    use Phoenix.LiveView

    alias AshUITutorials.ProjectShell.Web.Components.TutorialShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      _ = AshUITutorials.ProjectShell.seed!()
      example_runtime = runtime_from_params(params)

      socket =
        socket
        |> Phoenix.Component.assign(:current_user, AshUITutorials.ProjectShell.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUITutorials.ProjectShell.ui_storage())
        |> Phoenix.Component.assign(:ash_ui_domains, AshUITutorials.ProjectShell.runtime_domains())
        |> Phoenix.Component.assign(:page_title, AshUITutorials.ProjectShell.title())
        |> Phoenix.Component.assign(:theme_css, AshUITutorials.ProjectShell.theme_css())
        |> Phoenix.Component.assign(:example_runtime, example_runtime)
        |> Phoenix.Component.assign(:supported_runtimes, AshUITutorials.ProjectShell.supported_runtimes())

      with {:ok, socket} <- Integration.mount_ui_screen(socket, AshUITutorials.ProjectShell.screen_name(), params),
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
      assigns =
        assigns
        |> Phoenix.Component.assign_new(:supported_runtimes, fn -> AshUITutorials.ProjectShell.supported_runtimes() end)
        |> Phoenix.Component.assign_new(:example_runtime, fn -> AshUITutorials.ProjectShell.default_runtime() end)
        |> Phoenix.Component.assign_new(:rendered_runtime, fn ->
          %{
            content: assigns[:rendered_ui] || "",
            description: AshUITutorials.ProjectShell.runtime_description(AshUITutorials.ProjectShell.default_runtime()),
            mode: :live_fragment,
            runtime: AshUITutorials.ProjectShell.default_runtime()
          }
        end)

      ~H"""
      <TutorialShell.tutorial_shell title={@page_title} summary={AshUITutorials.ProjectShell.summary()} theme_css={@theme_css}>
        <section class="ashui-example-panel ashui-tutorial-runtime-panel">
          <div>
            <h2>Runtime preview: <%= @rendered_runtime.runtime %></h2>
            <p class="ashui-tutorial-muted-copy"><%= @rendered_runtime.description %></p>
          </div>
          <div class="ashui-tutorial-runtime-actions">
            <%= for runtime <- @supported_runtimes do %>
              <code class="ashui-tutorial-runtime-command">mix example.start <%= runtime %></code>
            <% end %>
          </div>
        </section>
        <section class="ashui-tutorial-runtime-view">
          <%= case @rendered_runtime.mode do %>
            <% :html_document -> %>
              <iframe class="ashui-tutorial-runtime-frame" sandbox="allow-same-origin" srcdoc={@rendered_runtime.content} title={"project-shell-#{@rendered_runtime.runtime}"} />
            <% :desktop_instructions -> %>
              <pre class="ashui-tutorial-runtime-pre"><%= @rendered_runtime.content %></pre>
            <% :live_fragment -> %>
              <%= Phoenix.HTML.raw(@rendered_runtime.content) %>
          <% end %>
        </section>
      </TutorialShell.tutorial_shell>
      """
    end

    defp refresh_rendered_ui(socket) do
      rendered_runtime =
        AshUITutorials.ProjectShell.rendered_runtime(
          socket.assigns,
          socket.assigns[:example_runtime] || AshUITutorials.ProjectShell.default_runtime()
        )

      socket
      |> Phoenix.Component.assign(:rendered_runtime, rendered_runtime)
      |> Phoenix.Component.assign(:rendered_ui, rendered_runtime.content)
    end

    defp runtime_from_params(params) do
      params["runtime"]
      |> fallback_runtime()
      |> AshUITutorials.ProjectShell.normalize_runtime!()
    end

    defp fallback_runtime(nil), do: System.get_env("ASH_UI_EXAMPLE_RUNTIME")
    defp fallback_runtime(runtime), do: runtime
  end
end
