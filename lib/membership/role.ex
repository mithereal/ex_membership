defmodule Membership.Role do
  @moduledoc """
  Role is main representation of feature flags assigned to a role
  """
  use Membership.Schema
  import Ecto.Query

  alias Membership.Role
  alias Membership.RoleFeatures

  @typedoc "A Role struct"
  @type t :: %Role{}

  schema "membership_roles" do
    field(:identifier, :string)
    field(:name, :string)

    many_to_many(:features, Features,
      join_through: RoleFeatures,
      on_replace: :delete
    )
  end

  def changeset(%Role{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:identifier, :name])
    |> cast_assoc(:plans, required: false)
    |> validate_required([:identifier, :name])
    |> unique_constraint(:identifier, message: "Role already exists")
  end

  def build(identifier, name) do
    changeset(%Role{}, %{
      identifier: identifier,
      name: name
    })
  end

  def create(identifier, name) do
    record = Repo.get_by(Role, identifier: identifier)

    case is_nil(record) do
      true ->
        {_, record} = Repo.insert(%Role{identifier: identifier, name: name})
        record

      false ->
        record
    end
  end

  def table, do: :membership_features

  @doc """
  Grant given grant type to a feature.

  ## Examples

  Function accepts either `Membership.Role` or `Membership.Plan` grants.
  Function is merging existing grants with the new ones, so calling grant with same
  grants will not duplicate entries in table.

  To grant particular feature to a given plan

      iex> Membership.Role.grant(%Membership.Plan{id: 1}, %Membership.Role{id: 1})

  To grant particular feature to a given plan

      iex> Membership.Role.grant(%Membership.Role{id: 1}, %Membership.Plan{id: 1})

  """

  @spec grant(Role.t(), Role.t() | Plan.t()) :: Member.t()
  def grant(%Role{id: id} = _member, %Plan{id: _id} = plan) do
    # Preload Role plans
    feature = Role |> Repo.get!(id) |> Repo.preload(:plans)

    plans = merge_uniq_grants(feature.plans ++ [plan])

    changeset =
      changeset(feature)
      |> put_assoc(:plans, plans)

    changeset |> Repo.update()
  end

  def grant(%{feature: %Role{id: _pid} = feature}, %Plan{id: _id} = plan) do
    grant(feature, plan)
  end

  def grant(%{feature_id: id}, %Plan{id: _id} = plan) do
    feature = Role |> Repo.get!(id)
    grant(feature, plan)
  end

  def grant(%Plan{id: id} = _member, %Role{id: _id} = feature) do
    plan = Plan |> Repo.get!(id) |> Repo.preload(:features)
    features = Enum.uniq(plan.features ++ [feature])

    changeset =
      Plan.changeset(plan)
      |> put_change(:features, features)

    changeset |> Repo.update!()
  end

  def grant(%{plan: %Plan{id: id}}, %Role{id: _id} = feature) do
    plan = Plan |> Repo.get!(id)
    grant(plan, feature)
  end

  def grant(%{plan_id: id}, %Role{id: _id} = feature) do
    plan = Member |> Repo.get!(id)
    grant(plan, feature)
  end

  def grant(_, _), do: raise(ArgumentError, message: "Bad arguments for giving grant")

  def grant(_, _, _), do: raise(ArgumentError, message: "Bad arguments for giving grant")

  @doc """
  Revoke given grant type from a member.

  ## Examples

  Function accepts either `Membership.Role` or `Membership.Plan` grants.
  Function is directly opposite of `Membership.Member.grant/2`

  To revoke particular feature from a given plan

      iex> Membership.Role.revoke(%Membership.Plan{id: 1}, %Membership.Role{id: 1})

  To revoke particular plan from a given feature

      iex> Membership.Role.revoke(%Membership.Role{id: 1}, %Membership.Plan{id: 1})

  """
  @spec revoke(Plan.t(), Role.t() | Plan.t()) :: Member.t()
  def revoke(%Role{id: id} = _, %Plan{id: _id} = plan) do
    from(pa in PlanRoles)
    |> where([pr], pr.feature_id == ^id and pr.plan_id == ^plan.id)
    |> Repo.delete_all()
  end

  def revoke(%{feature: %Role{id: _pid} = feature}, %Plan{id: _id} = plan) do
    revoke(feature, plan)
  end

  def revoke(%{feature_id: id}, %Plan{id: _id} = plan) do
    revoke(%Role{id: id}, plan)
  end

  def revoke(%Plan{id: id} = _member, %Role{id: _id} = feature) do
    plan = Plan |> Repo.get!(id) |> Repo.preload(:features)

    features =
      Enum.filter(plan.features, fn grant ->
        grant != feature.identifier
      end)

    changeset =
      Plan.changeset(plan)
      |> put_change(:features, features)

    changeset |> Repo.update!()
  end

  def revoke(
        %{plan: %Plan{id: _pid} = plan},
        %Role{id: _id} = feature
      ) do
    revoke(plan, feature)
  end

  def revoke(%{plan_id: id}, %Role{id: _id} = feature) do
    revoke(%Plan{id: id}, feature)
  end

  def revoke(_, _), do: raise(ArgumentError, message: "Bad arguments for revoking grant")

  def revoke(_, _, _), do: raise(ArgumentError, message: "Bad arguments for revoking grant")

  def load_plan_feature(plan, %{
        __struct__: _feature_name,
        id: feature_id,
        identifier: _identifier
      }) do
    PlanRoles
    |> where(
      [e],
      e.plan_id == ^plan.id and e.feature_id == ^feature_id
    )
    |> Repo.one()
  end

  defp merge_uniq_grants(grants) do
    Enum.uniq_by(grants, fn grant ->
      grant.identifier
    end)
  end
end
