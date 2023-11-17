defmodule Membership.Feature do
  @moduledoc false
  use Membership.Schema
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
    changeset(%Feature{}, %{
      identifier: identifier,
      name: name
    })
    |> Repo.insert_or_update()
  end

  def table, do: :membership_features

  @spec grant(Feature.t(), Feature.t() | Plan.t()) :: Member.t()
  def grant(%Feature{id: id} = _feature, %Plan{id: plan_id} = _plan) do
    # Preload Feature plans
    feature = Feature |> Repo.get!(id)
    plan = Plan |> Repo.get!(plan_id)

    revoke(feature, plan)

    %PlanFeatures{plan_id: plan.id, feature_id: feature.id}
    |> Repo.insert()

    {:ok, Feature |> Repo.get!(id) |> Repo.preload(:plans)}
  end

  def grant(%{feature: %Feature{id: _pid} = feature}, %Plan{id: _id} = plan) do
    grant(feature, plan)
  end

  def grant(%{feature_id: id}, %Plan{id: _id} = plan) do
    feature = Feature |> Repo.get!(id)
    grant(feature, plan)
  end

  def grant(%Plan{id: plan_id} = _member, %Feature{id: id} = _feature) do
    # Preload Feature plans
    feature = Feature |> Repo.get!(id)
    plan = Plan |> Repo.get!(plan_id)

    revoke(feature, plan)

    %PlanFeatures{plan_id: plan.id, feature_id: feature.id}
    |> Repo.insert()

    {:ok, Feature |> Repo.get!(id) |> Repo.preload(:plans)}
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
    feature = Feature |> Repo.get!(id)
    role = Role |> Repo.get!(role_id)

    revoke(feature, role)

    RoleFeatures.changeset(%Membership.RoleFeatures{}, %{role_id: role.id, feature_id: feature.id})
    |> Repo.insert()

    {:ok, Feature |> Repo.get!(id) |> Repo.preload(:roles)}
  end

  def grant(%{feature: %Feature{id: _id} = feature}, %Role{id: _role_id} = role) do
    grant(feature, role)
  end

  def grant(%{feature_id: id}, %Role{id: _id} = role) do
    grant(%Feature{id: id}, role)
  end

  def grant(_, _), do: raise(ArgumentError, message: "Bad arguments for giving grant")

  def grant(_, _, _), do: raise(ArgumentError, message: "Bad arguments for giving grant")

  @spec revoke(Plan.t(), Feature.t() | Plan.t()) :: Member.t()
  def revoke(%Feature{id: id} = _, %Plan{id: _id} = plan) do
    from(pa in PlanFeatures)
    |> where([pr], pr.feature_id == ^id and pr.plan_id == ^plan.id)
    |> Repo.delete_all()
  end

  def revoke(%{feature: %Feature{id: _pid} = feature}, %Plan{id: _id} = plan) do
    revoke(feature, plan)
  end

  def revoke(%{feature_id: id}, %Plan{id: _id} = plan) do
    revoke(%Feature{id: id}, plan)
  end

  def revoke(%Plan{id: _id} = plan, %Feature{id: feature_id} = _feature) do
    from(pa in PlanFeatures)
    |> where([pr], pr.feature_id == ^feature_id and pr.plan_id == ^plan.id)
    |> Repo.delete_all()
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
    from(pa in RoleFeatures)
    |> where([pr], pr.feature_id == ^id and pr.role_id == ^role.id)
    |> Repo.delete_all()
  end

  def revoke(%Role{id: _id} = role, %Feature{id: feature_id} = _feature) do
    from(pa in RoleFeatures)
    |> where([pr], pr.feature_id == ^feature_id and pr.plan_id == ^role.id)
    |> Repo.delete_all()
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
    PlanFeatures
    |> where(
      [e],
      e.plan_id == ^plan.id and e.feature_id == ^feature_id
    )
    |> Repo.one()
  end
end
