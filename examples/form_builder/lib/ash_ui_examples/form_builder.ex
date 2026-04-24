defmodule AshUIExamples.FormBuilder do
  @moduledoc """
  Standalone resource-authority Ash UI app for the `form_builder` example.
  """

  use Phoenix.Component

  alias AshUI.LiveView.EventHandler
  alias AshUI.LiveView.Integration
  alias AshUI.Rendering.LiveUIAdapter
  alias AshUI.Resource.Authority

  @directory "form_builder"
  @screen_name "example/form_builder"
  @definition %{
    directory: "form_builder",
    family: :forms,
    title: "Form Builder Example",
    section: :form_scaffolding,
    subject_type: :form_builder,
    subject_props: %{class: "ashui-example-form"},
    story_text:
      "Meaningful Interaction Story: edit the nested display-name field and submit the form to confirm the authored form shell owns the review surface while the write and submit flow stay local to the resource graph.",
    signal_text:
      "Canonical Signal Preview: nested input change -> ExampleState.display_value; form submit -> ExampleState.submitted_value and ExampleState.status.",
    seed_state: %{
      id: "state-form_builder",
      status: "Awaiting form submission",
      display_value: "Ada Example",
      current_value: "Ada Example",
      submitted_value: "Not submitted"
    },
    preview_field: :submitted_value,
    preview_title: "Last submitted value",
    subject_binding: nil,
    subject_action: %{
      id: :submit_profile,
      metadata: %{owner: "form_builder", intent: "submit_profile"},
      signal: :submit,
      params: %{
        status: %{
          "from" => "static",
          "value" => "Form submitted through form_builder"
        },
        submitted_value: %{"from" => "binding", "key" => "display_name"}
      }
    },
    subject_children: [
      %{
        position: 0,
        type: :form_field,
        key: :display_name_field,
        children: [
          %{
            position: 0,
            type: :input,
            bindings: [
              %{
                id: :display_name_input,
                metadata: %{owner: "input", owner_signal: "change"},
                source: %{
                  id: "state-form_builder",
                  resource: "ExampleState",
                  field: :display_value
                },
                target: "display_name",
                transform: %{},
                binding_type: :value
              }
            ],
            key: :display_name_input,
            children: [],
            props: %{
              name: "display_name",
              type: "text",
              value: "Ada Example",
              class: "ashui-example-input",
              placeholder: "Ada Example"
            }
          }
        ],
        props: %{
          label: "Display name",
          name: "display_name",
          help: "Bound locally and submitted through the form builder.",
          class: "ashui-example-form-field"
        }
      },
      %{
        position: 10,
        type: :button,
        key: :submit_button,
        children: [],
        props: %{
          label: "Save profile",
          type: "submit",
          class: "ashui-example-primary-cta",
          variant: "primary"
        }
      }
    ],
    support_notice:
      "The example uses `form_builder` as the public subject and keeps submit handling local to the authored form resource.",
    notes: "Promotes form_builder from fallback-only rendering into the public example suite."
  }
  @theme_css File.read!(Path.expand("../../assets/css/app.css", __DIR__))

  def app, do: :ash_ui_example_form_builder
  def definition, do: @definition
  def title, do: @definition.title
  def theme_css, do: @theme_css
  def screen_name, do: @screen_name

  def ui_storage do
    [
      domain: AshUIExamples.FormBuilder.UiStorageDomain,
      resources: [
        screen: AshUIExamples.FormBuilder.UiScreen,
        element: AshUIExamples.FormBuilder.UiElement,
        binding: AshUIExamples.FormBuilder.UiBinding
      ],
      repo: nil
    ]
  end

  def runtime_domains, do: [AshUIExamples.FormBuilder.RuntimeDomain]

  def current_user,
    do: %{
      active: true,
      id: "reviewer-form_builder",
      name: "Example Reviewer",
      role: :admin
    }

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
        id: "state-form_builder",
        status: "Awaiting form submission",
        display_value: "Ada Example",
        current_value: "Ada Example",
        submitted_value: "Not submitted"
      }
    )
  end

  def reset! do
    reset_resource!(
      AshUIExamples.FormBuilder.Runtime.ExampleState,
      AshUIExamples.FormBuilder.RuntimeDomain
    )

    reset_resource!(
      AshUIExamples.FormBuilder.UiBinding,
      AshUIExamples.FormBuilder.UiStorageDomain
    )

    reset_resource!(
      AshUIExamples.FormBuilder.UiElement,
      AshUIExamples.FormBuilder.UiStorageDomain
    )

    reset_resource!(AshUIExamples.FormBuilder.UiScreen, AshUIExamples.FormBuilder.UiStorageDomain)
    :ok
  end

  def seed!(opts \\ []) do
    actor = Keyword.get(opts, :actor, current_user())
    reset!()

    {:ok, _state} =
      Ash.create(
        AshUIExamples.FormBuilder.Runtime.ExampleState,
        seed_state(),
        domain: AshUIExamples.FormBuilder.RuntimeDomain,
        authorize?: false
      )

    {:ok, screen} =
      Authority.create(
        AshUIExamples.FormBuilder.Examples.FormBuilderScreen,
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
        {Phoenix.PubSub, name: AshUIExamples.FormBuilder.PubSub},
        AshUIExamples.FormBuilder.Web.Endpoint
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
    end
  end

  defmodule RuntimeDomain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource(AshUIExamples.FormBuilder.Runtime.ExampleState)
    end
  end

  defmodule Runtime.ExampleState do
    use Ash.Resource,
      domain: AshUIExamples.FormBuilder.RuntimeDomain,
      data_layer: Ash.DataLayer.Ets

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
      resource(AshUIExamples.FormBuilder.UiScreen)
      resource(AshUIExamples.FormBuilder.UiElement)
      resource(AshUIExamples.FormBuilder.UiBinding)
    end
  end

  defmodule UiScreen do
    use Ash.Resource,
      domain: AshUIExamples.FormBuilder.UiStorageDomain,
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
      has_many :elements, AshUIExamples.FormBuilder.UiElement do
        destination_attribute(:screen_id)
      end

      has_many :bindings, AshUIExamples.FormBuilder.UiBinding do
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
      domain: AshUIExamples.FormBuilder.UiStorageDomain,
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
      belongs_to :screen, AshUIExamples.FormBuilder.UiScreen do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      has_many :bindings, AshUIExamples.FormBuilder.UiBinding do
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
      domain: AshUIExamples.FormBuilder.UiStorageDomain,
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
      belongs_to :element, AshUIExamples.FormBuilder.UiElement do
        attribute_type(:uuid)
        allow_nil?(true)
      end

      belongs_to :screen, AshUIExamples.FormBuilder.UiScreen do
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
      resource(AshUIExamples.FormBuilder.Examples.FormBuilderScreen)
      resource(AshUIExamples.FormBuilder.Examples.FormBuilderDemoPanelElement)
      resource(AshUIExamples.FormBuilder.Examples.FormBuilderSubjectElement)
      resource(AshUIExamples.FormBuilder.Examples.FormBuilderPreviewElement)
      resource(AshUIExamples.FormBuilder.Examples.FormBuilderStoryTextElement)
      resource(AshUIExamples.FormBuilder.Examples.FormBuilderSignalTextElement)
      resource(AshUIExamples.FormBuilder.Examples.FormBuilderSupportNoticeElement)
      resource(AshUIExamples.FormBuilder.Examples.FormBuilderDisplayNameFieldElement)
      resource(AshUIExamples.FormBuilder.Examples.FormBuilderDisplayNameInputElement)
      resource(AshUIExamples.FormBuilder.Examples.FormBuilderSubmitButtonElement)
    end
  end

  defmodule ExampleElementBase do
    defmacro __using__(_opts) do
      quote do
        use Ash.Resource,
          domain: AshUIExamples.FormBuilder.AuthoringDomain,
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

  defmodule Examples.FormBuilderDemoPanelElement do
    use AshUIExamples.FormBuilder.ExampleElementBase

    relationships do
      has_many :subjects, AshUIExamples.FormBuilder.Examples.FormBuilderSubjectElement do
        destination_attribute(:parent_id)
      end

      has_many :previews, AshUIExamples.FormBuilder.Examples.FormBuilderPreviewElement do
        destination_attribute(:parent_id)
      end

      has_many :support_notices,
               AshUIExamples.FormBuilder.Examples.FormBuilderSupportNoticeElement do
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
      props(%{title: "Form Builder Example", class: "ashui-example-panel"})
      metadata(%{id: "example-form_builder-demo", section: "demo", slot: "body", position: 0})
    end
  end

  defmodule Examples.FormBuilderSubjectElement do
    use AshUIExamples.FormBuilder.ExampleElementBase

    relationships do
      has_many :display_name_field_elements,
               AshUIExamples.FormBuilder.Examples.FormBuilderDisplayNameFieldElement do
        destination_attribute(:parent_id)
      end

      has_many :submit_button_elements,
               AshUIExamples.FormBuilder.Examples.FormBuilderSubmitButtonElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :display_name_field_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end

      relationship :submit_button_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(10)
      end
    end

    ui_element do
      type(:form_builder)
      props(%{class: "ashui-example-form"})
      metadata(%{id: "example-form_builder-subject", section: "demo", slot: "body", position: 1})
    end

    ui_actions do
      action :submit_profile do
        signal(:submit)
        source(%{resource: "ExampleState", action: "update", id: "state-form_builder"})
        target("submit")

        transform(%{
          params: %{
            status: %{
              "from" => "static",
              "value" => "Form submitted through form_builder"
            },
            submitted_value: %{"from" => "binding", "key" => "display_name"}
          }
        })

        metadata(%{owner: "form_builder", intent: "submit_profile"})
      end
    end
  end

  defmodule Examples.FormBuilderDisplayNameFieldElement do
    use AshUIExamples.FormBuilder.ExampleElementBase

    relationships do
      has_many :display_name_input_elements,
               AshUIExamples.FormBuilder.Examples.FormBuilderDisplayNameInputElement do
        destination_attribute(:parent_id)
      end
    end

    ui_relationships do
      relationship :display_name_input_elements do
        kind(:child)
        slot(:body)
        placement(:append)
        order(0)
      end
    end

    ui_element do
      type(:form_field)

      props(%{
        label: "Display name",
        name: "display_name",
        help: "Bound locally and submitted through the form builder.",
        class: "ashui-example-form-field"
      })

      metadata(%{id: "display-name-field", position: 0, slot: "body", section: "demo"})
    end
  end

  defmodule Examples.FormBuilderSubmitButtonElement do
    use AshUIExamples.FormBuilder.ExampleElementBase

    ui_element do
      type(:button)

      props(%{
        label: "Save profile",
        type: "submit",
        class: "ashui-example-primary-cta",
        variant: "primary"
      })

      metadata(%{id: "submit-button", position: 10, slot: "body", section: "demo"})
    end
  end

  defmodule Examples.FormBuilderDisplayNameInputElement do
    use AshUIExamples.FormBuilder.ExampleElementBase

    ui_element do
      type(:input)

      props(%{
        name: "display_name",
        type: "text",
        value: "Ada Example",
        class: "ashui-example-input",
        placeholder: "Ada Example"
      })

      metadata(%{id: "display-name-input", position: 0, slot: "body", section: "demo"})
    end

    ui_bindings do
      binding :display_name_input do
        source(%{id: "state-form_builder", resource: "ExampleState", field: :display_value})
        target("display_name")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "input", owner_signal: "change"})
      end
    end
  end

  defmodule Examples.FormBuilderPreviewElement do
    use AshUIExamples.FormBuilder.ExampleElementBase

    ui_element do
      type(:stat)
      props(%{title: "Last submitted value", value: "Not submitted"})
      variants([:primary])
      metadata(%{id: "example-form_builder-preview", section: "demo", slot: "body", position: 2})
    end

    ui_bindings do
      binding :preview_value do
        source(%{resource: "ExampleState", field: :submitted_value, id: "state-form_builder"})
        target("value")
        binding_type(:value)
        transform(%{})
        metadata(%{owner: "preview"})
      end
    end
  end

  defmodule Examples.FormBuilderStoryTextElement do
    use AshUIExamples.FormBuilder.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Meaningful Interaction Story: edit the nested display-name field and submit the form to confirm the authored form shell owns the review surface while the write and submit flow stay local to the resource graph.",
        class: "ashui-example-code-surface"
      })

      metadata(%{id: "example-form_builder-story", section: "story", slot: "body", position: 10})
    end
  end

  defmodule Examples.FormBuilderSignalTextElement do
    use AshUIExamples.FormBuilder.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "Canonical Signal Preview: nested input change -> ExampleState.display_value; form submit -> ExampleState.submitted_value and ExampleState.status.",
        class: "ashui-example-code-surface"
      })

      metadata(%{
        id: "example-form_builder-signal-preview",
        section: "signal_preview",
        slot: "body",
        position: 20
      })
    end
  end

  defmodule Examples.FormBuilderSupportNoticeElement do
    use AshUIExamples.FormBuilder.ExampleElementBase

    ui_element do
      type(:text)

      props(%{
        content:
          "The example uses `form_builder` as the public subject and keeps submit handling local to the authored form resource.",
        class: "ashui-example-focus-ring"
      })

      metadata(%{
        id: "example-form_builder-support-note",
        section: "demo",
        slot: "body",
        position: 3
      })
    end
  end

  defmodule Examples.FormBuilderScreen do
    use Ash.Resource,
      domain: AshUIExamples.FormBuilder.AuthoringDomain,
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
      has_many :demo_panels, AshUIExamples.FormBuilder.Examples.FormBuilderDemoPanelElement do
        destination_attribute(:screen_id)
      end

      has_many :story_texts, AshUIExamples.FormBuilder.Examples.FormBuilderStoryTextElement do
        destination_attribute(:screen_id)
      end

      has_many :signal_texts, AshUIExamples.FormBuilder.Examples.FormBuilderSignalTextElement do
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
        title: "Form Builder Example",
        example_directory: "form_builder",
        shell_id: "example-form_builder-shell"
      })
    end
  end

  defmodule ExampleSeeds do
    def seed!(opts \\ []), do: AshUIExamples.FormBuilder.seed!(opts)
    def reset!, do: AshUIExamples.FormBuilder.reset!()
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

    scope "/", AshUIExamples.FormBuilder.Web do
      pipe_through(:browser)
      live("/", ExampleLive)
    end
  end

  defmodule Web.Endpoint do
    use Phoenix.Endpoint, otp_app: :ash_ui_example_form_builder

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
    plug(AshUIExamples.FormBuilder.Web.Router)
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

    alias AshUIExamples.FormBuilder.Web.Components.ExampleShell
    alias AshUI.LiveView.EventHandler
    alias AshUI.LiveView.Integration

    def mount(params, _session, socket) do
      _ = AshUIExamples.FormBuilder.seed!()

      socket =
        socket
        |> Phoenix.Component.assign(:current_user, AshUIExamples.FormBuilder.current_user())
        |> Phoenix.Component.assign(:ash_ui_storage, AshUIExamples.FormBuilder.ui_storage())
        |> Phoenix.Component.assign(:ash_ui_domains, AshUIExamples.FormBuilder.runtime_domains())
        |> Phoenix.Component.assign(:page_title, "Form Builder Example")
        |> Phoenix.Component.assign(:example_directory, "form_builder")
        |> Phoenix.Component.assign(:theme_css, AshUIExamples.FormBuilder.theme_css())

      with {:ok, socket} <- Integration.mount_ui_screen(socket, "example/form_builder", params),
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
      ~H"""
      <ExampleShell.example_shell
        title={@page_title}
        directory={@example_directory}
        summary={"Meaningful Interaction Story: edit the nested display-name field and submit the form to confirm the authored form shell owns the review surface while the write and submit flow stay local to the resource graph."}
        theme_css={@theme_css}
      >
        <%= Phoenix.HTML.raw(@rendered_ui || "") %>
      </ExampleShell.example_shell>
      """
    end

    defp refresh_rendered_ui(socket) do
      Phoenix.Component.assign(
        socket,
        :rendered_ui,
        AshUIExamples.FormBuilder.rendered_ui(socket.assigns)
      )
    end
  end
end
