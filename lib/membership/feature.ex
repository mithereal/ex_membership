defmodule Membership.Feature do
  @moduledoc """
  Feature is main representation of a single feature flag assigned to a plan
  """
  use Membership.Schema

  @config Membership.Config.new()
  import Ecto.Query

  alias Membership.Feature
  alias Membership.PlanFeatures
  alias Membership.RoleFeatures
  alias Membership.Plan
  alias Membership.Role

  @typedoc "A Feature struct"
  @type t :: %Feature{}

  schema "membership_features" do
    field(:identifier, :string)
    field(:name, :string)

    many_to_many(:plans, Plan,
      join_through: PlanFeatures,
      on_replace: :delete
    )

    many_to_many(:roles, Role,
      join_through: RoleFeatures,
      on_replace: :delete
    )
  end

  def changeset(%Feature{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:identifier, :name])
    |> cast_assoc(:plans, required: false)
    |> cast_assoc(:roles, required: false)
    |> validate_required([:identifier, :name])
    |> unique_constraint(:identifier, message: "Feature already exists")
  end

  def build(identifier, name) do
    changeset(%Feature{}, %{
      identifier: identifier,
      name: name
    })
    |> Ecto.Changeset.apply_changes()
  end

  def create(identifier, name) do
    changeset =
      changeset(%Feature{}, %{
        identifier: identifier,
        name: name
      })

    @config
    |> Repo.insert_or_update(changeset)
  end

  def table, do: :membership_features

  @doc """
  Grant given grant type to a feature.

  ## Examples

  Function accepts either `Membership.Feature` or `Membership.Plan` grants.
  Function is merging existing grants with the new ones, so calling grant with same
  grants will not duplicate entries in table.

  To grant particular feature to a given plan

      iex> Membership.Feature.grant(%Membership.Plan{id: 1}, %Membership.Feature{id: 1})

  To grant particular feature to a given plan

      iex> Membership.Feature.grant(%Membership.Feature{id: 1}, %Membership.Plan{id: 1})

  """

  @spec grant(Feature.t(), Feature.t() | Plan.t()) :: Member.t()
  def grant(%Feature{id: id} = _feature, %Plan{id: plan_id} = _plan) do
    # Preload Feature plans
    feature =
      @config
      |> Repo.get!(Feature, id)

    plan = @config |> Repo.get!(Plan, plan_id)

    revoke(feature, plan)

    @config
    |> Repo.insert(%PlanFeatures{plan_id: plan.id, feature_id: feature.id})

    {:ok, @config |> Repo.get!(Feature, id) |> Repo.preload(:plans)}
  end

  def grant(%{feature: %Feature{id: _pid} = feature}, %Plan{id: _id} = plan) do
    grant(feature, plan)
  end

  def grant(%{feature_id: id}, %Plan{id: _id} = plan) do
    feature = @config |> Repo.get!(Feature, id)
    grant(feature, plan)
  end

  def grant(%Plan{id: plan_id} = _member, %Feature{id: id} = _feature) do
    # Preload Feature plans
    feature = @config |> Repo.get!(Feature, id)
    plan = @config |> Repo.get!(Plan, plan_id)

    revoke(feature, plan)

    @config
    |> Repo.insert(%PlanFeatures{plan_id: plan.id, feature_id: feature.id})

    {:ok, @config |> Repo.get!(Feature, id) |> Repo.preload(:plans)}
  end

  def grant(%{plan: %Plan{id: id}}, %Feature{id: _id} = feature) do
    %Plan{id: id}
    |> grant(feature)
  end

  def grant(%{plan_id: id}, %Feature{id: _id} = feature) do
    %Plan{id: id}
    |> grant(feature)
  end

  #####

  @spec grant(Feature.t(), Feature.t() | Role.t()) :: Member.t()
  def grant(%Feature{id: id} = _feature, %Role{id: role_id} = _role) do
    # Preload Feature plans
    feature = @config |> Repo.get!(Feature, id)
    role = @config |> Repo.get!(Role, role_id)

    revoke(feature, role)

    @config
    |> Repo.insert(
      RoleFeatures.changeset(%Membership.RoleFeatures{}, %{
        role_id: role.id,
        feature_id: feature.id
      })
    )

    {:ok, @config |> Repo.get!(Feature, id) |> Repo.preload(:roles)}
  end

  def grant(%{feature: %Feature{id: _id} = feature}, %Role{id: _role_id} = role) do
    grant(feature, role)
  end

  def grant(%{feature_id: id}, %Role{id: _id} = role) do
    grant(%Feature{id: id}, role)
  end

  def grant(_, _), do: raise(ArgumentError, message: "Bad arguments for giving grant")

  def grant(_, _, _), do: raise(ArgumentError, message: "Bad arguments for giving grant")

  @doc """
  Revoke given grant type from a member.

  ## Examples

  Function accepts either `Membership.Feature` or `Membership.Plan` grants.
  Function is directly opposite of `Membership.Member.grant/2`

  To revoke particular feature from a given plan

      iex> Membership.Feature.revoke(%Membership.Plan{id: 1}, %Membership.Feature{id: 1})

  To revoke particular plan from a given feature

      iex> Membership.Feature.revoke(%Membership.Feature{id: 1}, %Membership.Plan{id: 1})

  """
  @spec revoke(Plan.t(), Feature.t() | Plan.t()) :: Member.t()
  def revoke(%Feature{id: id} = _, %Plan{id: _id} = plan) do
    query =
      from(pa in PlanFeatures)
      |> where([pr], pr.feature_id == ^id and pr.plan_id == ^plan.id)

    @query |> Repo.delete_all()
  end

  def revoke(%{feature: %Feature{id: _pid} = feature}, %Plan{id: _id} = plan) do
    revoke(feature, plan)
  end

  def revoke(%{feature_id: id}, %Plan{id: _id} = plan) do
    revoke(%Feature{id: id}, plan)
  end

  def revoke(%Plan{id: _id} = plan, %Feature{id: feature_id} = _feature) do
    query =
      from(pa in PlanFeatures)
      |> where([pr], pr.feature_id == ^feature_id and pr.plan_id == ^plan.id)

    @query |> Repo.delete_all(query)
  end

  def revoke(
        %{plan: %Plan{id: _pid} = plan},
        %Feature{id: _id} = feature
      ) do
    revoke(plan, feature)
  end

  def revoke(%{plan_id: id}, %Feature{id: _id} = feature) do
    revoke(%Plan{id: id}, feature)
  end

  ###

  def revoke(%Feature{id: id} = _, %Role{id: _id} = role) do
    query =
      from(pa in RoleFeatures)
      |> where([pr], pr.feature_id == ^id and pr.role_id == ^role.id)

    @query |> Repo.delete_all(query)
  end

  def revoke(%Role{id: _id} = role, %Feature{id: feature_id} = _feature) do
    query =
      from(pa in RoleFeatures)
      |> where([pr], pr.feature_id == ^feature_id and pr.plan_id == ^role.id)

    @query |> Repo.delete_all(query)
  end

  def revoke(
        %{role: %Role{id: _pid} = role},
        %Feature{id: _id} = feature
      ) do
    revoke(role, feature)
  end

  def revoke(%{role_id: id}, %Feature{id: _id} = feature) do
    revoke(%Role{id: id}, feature)
  end

  def revoke(_, _), do: raise(ArgumentError, message: "Bad arguments for revoking grant")

  def revoke(_, _, _), do: raise(ArgumentError, message: "Bad arguments for revoking grant")

  def load_plan_feature(plan, %{
        __struct__: _feature_name,
        id: feature_id,
        identifier: _identifier
      }) do
    query =
      PlanFeatures
      |> where(
        [e],
        e.plan_id == ^plan.id and e.feature_id == ^feature_id
      )

    @config
    |> Repo.one(query)
  end
end
