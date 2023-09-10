defmodule Membership.Role do
  @moduledoc """
  Role is main representation of feature flags assigned to a role
  """
  use Membership.Schema
  import Ecto.Query

  alias Membership.Role
  alias Membership.Feature
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
    |> cast_assoc(:features, required: false)
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

  Function accepts either `Membership.Role` or `Membership.Feature` grants.
  Function is merging existing grants with the new ones, so calling grant with same
  grants will not duplicate entries in table.

  To grant particular feature to a given role

      iex> Membership.Role.grant(%Membership.Feature{id: 1}, %Membership.Role{id: 1})

  To grant particular feature to a given role

      iex> Membership.Role.grant(%Membership.Role{id: 1}, %Membership.Feature{id: 1})

  """

  @spec grant(Role.t(), Role.t() | Feature.t()) :: Member.t()
  def grant(%Role{id: id} = _member, %Feature{id: _id} = feature) do
    # Preload Role features
    role = Role |> Repo.get!(id) |> Repo.preload(:features)

    features = merge_uniq_grants(role.features ++ [feature])

    changeset =
      changeset(feature)
      |> put_assoc(:features, features)

    changeset |> Repo.update()
  end

  def grant(%{role: %Role{id: _pid} = role}, %Feature{id: _id} = feature) do
    grant(role, feature)
  end

  def grant(%{role_id: id}, %Feature{id: _id} = feature) do
    role = Role |> Repo.get!(id)
    grant(role, feature)
  end

  def grant(%Feature{id: id} = feature, %Role{id: _id} = role) do
    role = Role |> Repo.get!(id) |> Repo.preload(:features)
    features = Enum.uniq(role.features ++ [feature])

    changeset =
      Role.changeset(Role)
      |> put_change(:features, features)

    changeset |> Repo.update!()
  end

  def grant(%{feature: %Feature{id: id}}, %Role{id: _id} = role) do
    feature = Feature |> Repo.get!(id)
    grant(role, feature)
  end

  def grant(%{feature_id: id}, %Role{id: _id} = role) do
    feature = Feature |> Repo.get!(id)
    grant(role, feature)
  end

  def grant(_, _), do: raise(ArgumentError, message: "Bad arguments for giving grant")

  def grant(_, _, _), do: raise(ArgumentError, message: "Bad arguments for giving grant")

  @doc """
  Revoke given grant type from a member.

  ## Examples

  Function accepts either `Membership.Role` or `Membership.Plan` grants.
  Function is directly opposite of `Membership.Member.grant/2`

  To revoke particular feature from a given plan

      iex> Membership.Role.revoke(%Membership.Feature{id: 1}, %Membership.Role{id: 1})

  To revoke particular plan from a given feature

      iex> Membership.Role.revoke(%Membership.Role{id: 1}, %Membership.Feature{id: 1})

  """
  @spec revoke(Plan.t(), Role.t() | Plan.t()) :: Member.t()
  def revoke(%Role{id: id} = _, %Feature{id: _id} = feature) do
    from(pa in PlanRoles)
    |> where([pr], pr.role_id == ^id and pr.feature_id == ^feature.id)
    |> Repo.delete_all()
  end

  def revoke(%{feature: %Role{id: _pid} = feature}, %Feature{id: _id} = plan) do
    revoke(feature, plan)
  end

  def revoke(%{feature_id: id}, %Feature{id: _id} = plan) do
    revoke(%Role{id: id}, plan)
  end

  def revoke(%Feature{id: id} = _member, %Role{id: _id} = feature) do
    role = Role |> Repo.get!(id) |> Repo.preload(:features)

    features =
      Enum.filter(role.features, fn grant ->
        grant != feature.identifier
      end)

    changeset =
      Plan.changeset(role)
      |> put_change(:features, features)

    changeset |> Repo.update!()
  end

  def revoke(
        %{feature: %Feature{id: _pid} = feature},
        %Role{id: _id} = role
      ) do
    revoke(role, feature)
  end

  def revoke(%{feature_id: id}, %Role{id: _id} = role) do
    revoke(%Feature{id: id}, role)
  end

  def revoke(_, _), do: raise(ArgumentError, message: "Bad arguments for revoking grant")

  def revoke(_, _, _), do: raise(ArgumentError, message: "Bad arguments for revoking grant")

  def load_role_feature(role, %{
        __struct__: _feature_name,
        id: feature_id,
        identifier: _identifier
      }) do
    PlanRoles
    |> where(
      [e],
      e.role_id == ^role.id and e.feature_id == ^feature_id
    )
    |> Repo.one()
  end

  defp merge_uniq_grants(grants) do
    Enum.uniq_by(grants, fn grant ->
      grant.identifier
    end)
  end
end
