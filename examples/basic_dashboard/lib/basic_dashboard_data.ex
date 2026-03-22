defmodule BasicDashboard.Domain do
  @moduledoc """
  Example Ash domain used by the basic dashboard reference app.
  """

  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource BasicDashboard.Profile
    resource BasicDashboard.User
  end
end

defmodule BasicDashboard.Profile do
  @moduledoc """
  In-memory profile data for the dashboard example.
  """

  @resource_topic_prefix "ash_ui:resource:BasicDashboard:Profile"

  use Ash.Resource,
    domain: BasicDashboard.Domain,
    notifiers: [Ash.Notifier.PubSub],
    data_layer: Ash.DataLayer.Ets

  ets do
    private? true
  end

  pub_sub do
    module AshUI.Notifications
    prefix @resource_topic_prefix

    publish :create, "changes"
    publish :update, "changes"
    publish :destroy, "changes"
  end

  attributes do
    attribute :id, :string do
      primary_key? true
      allow_nil? false
      public? true
    end

    attribute :name, :string, allow_nil?: false, public?: true
    attribute :team, :string, allow_nil?: false, public?: true
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:id, :name, :team]
    end

    update :update do
      primary? true
      accept [:name, :team]
    end
  end
end

defmodule BasicDashboard.User do
  @moduledoc """
  In-memory dashboard user data for the ETS-backed example.
  """

  @resource_topic_prefix "ash_ui:resource:BasicDashboard:User"

  use Ash.Resource,
    domain: BasicDashboard.Domain,
    notifiers: [Ash.Notifier.PubSub],
    data_layer: Ash.DataLayer.Ets

  ets do
    private? true
  end

  pub_sub do
    module AshUI.Notifications
    prefix @resource_topic_prefix

    publish :create, "changes"
    publish :update, "changes"
    publish :destroy, "changes"
  end

  attributes do
    attribute :id, :string do
      primary_key? true
      allow_nil? false
      public? true
    end

    attribute :name, :string, allow_nil?: false, public?: true
    attribute :email, :string, allow_nil?: false, public?: true
    attribute :status, :string, allow_nil?: false, public?: true
    attribute :last_actor_id, :string, public?: true
  end

  relationships do
    belongs_to :profile, BasicDashboard.Profile do
      attribute_type :string
      allow_nil? false
      public? true
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:id, :name, :email, :status, :last_actor_id, :profile_id]
    end

    update :update do
      primary? true
      accept [:name, :email, :status, :last_actor_id, :profile_id]
    end

    update :save_profile do
      argument :display_name, :string, allow_nil?: false
      argument :actor_id, :string

      change set_attribute(:name, arg(:display_name))
      change set_attribute(:last_actor_id, arg(:actor_id), set_when_nil?: false)
    end
  end
end

defmodule BasicDashboard.Data do
  @moduledoc """
  ETS-backed seed and read helpers for the basic dashboard example.
  """

  require Ash.Query

  alias BasicDashboard.Domain
  alias BasicDashboard.Profile
  alias BasicDashboard.User

  @current_profile_id "current-profile"
  @current_user_id "current-user"

  @spec seed!() :: %{actor: map(), profile: Profile.t(), user: User.t()}
  def seed! do
    reset_storage!()

    {:ok, profile} =
      Ash.create(
        Profile,
        %{
          id: @current_profile_id,
          name: "Operations",
          team: "Platform"
        },
        domain: Domain
      )

    {:ok, user} =
      Ash.create(
        User,
        %{
          id: @current_user_id,
          name: "Pascal",
          email: "pascal@example.com",
          status: "Active",
          profile_id: profile.id
        },
        domain: Domain
      )

    %{
      actor: actor(),
      profile: profile,
      user: user
    }
  end

  @spec actor() :: map()
  def actor do
    %{id: @current_user_id, role: :admin, active: true}
  end

  @spec current_user_id() :: String.t()
  def current_user_id, do: @current_user_id

  @spec snapshot!() :: %{profile: Profile.t(), user: User.t()}
  def snapshot! do
    user = read_one!(User, @current_user_id)
    profile = read_one!(Profile, user.profile_id)

    %{
      profile: profile,
      user: user
    }
  end

  defp read_one!(resource, id) do
    resource
    |> Ash.Query.new()
    |> Ash.Query.filter(id == ^id)
    |> Ash.read_one!(domain: Domain)
  end

  defp reset_storage! do
    Enum.each([User, Profile], fn resource ->
      resource
      |> Ash.DataLayer.Ets.stop()
      |> case do
        :ok -> :ok
        {:error, _reason} -> :ok
        _ -> :ok
      end
    end)
  rescue
    _ -> :ok
  end
end
