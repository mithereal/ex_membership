defmodule Membership.Role do
  @moduledoc false

  use Membership.Schema
  import Ecto.Query

  alias Membership.Role
  alias Membership.Role.Server
  alias Membership.Feature
  alias Membership.RoleFeatures

  @typedoc "A Role struct"
  @type t :: %Role{}

  schema "membership_roles" do
    field(:identifier, :string)
    field(:name, :string)

    many_to_many(:features, Feature,
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
    |> Ecto.Changeset.apply_changes()
  end

  def create(identifier, name, features \\ []) do
    role =
      changeset(%Role{}, %{
        identifier: identifier,
        name: name
      })
      |> Repo.insert_or_update()

    Enum.map(features, fn f ->
      Feature.create(f.identifier, f.name)
      |> Feature.grant(role)
    end)
  end

  def table, do: :membership_roles

  @spec grant(Role.t(), Role.t() | Feature.t()) :: Member.t()
  def grant(%Role{id: id} = _role, %Feature{id: feature_id} = _feature) do
    # Preload Role features
    role = Role |> Repo.get!(id)
    feature = Feature |> Repo.get!(feature_id)

    revoke(feature, role)

    %RoleFeatures{role_id: role.id, feature_id: feature.id}
    |> Repo.insert()

    Server.reload()
  end

  def grant(%{role: %Role{id: _pid} = role}, %Feature{id: _id} = feature) do
    grant(role, feature)
  end

  def grant(%{role_id: id}, %Feature{id: _id} = feature) do
    Role
    |> Repo.get!(id)
    |> grant(feature)
  end

  def grant(%Feature{id: feature_id} = _feature, %Role{id: id} = _role) do
    role = Role |> Repo.get!(id)
    feature = Feature |> Repo.get!(feature_id)

    revoke(feature, role)

    %RoleFeatures{role_id: role.id, feature_id: feature.id}
    |> Repo.insert()

    Server.reload()
  end

  def grant(%{feature: feature}, %Role{id: _id} = role) do
    grant(role, feature)
  end

  def grant(%{feature_id: id}, %Role{id: _id} = role) do
    grant(role, %Feature{id: id})
  end

  def grant(_, _), do: raise(ArgumentError, message: "Bad arguments for giving grant")

  def grant(_, _, _), do: raise(ArgumentError, message: "Bad arguments for giving grant")

  @spec revoke(Role.t(), Role.t() | Feature.t()) :: Member.t()
  def revoke(%Role{id: id} = _, %Feature{id: _id} = feature) do
    from(pa in RoleFeatures)
    |> where([pr], pr.role_id == ^id and pr.feature_id == ^feature.id)
    |> Repo.delete_all()
  end

  def revoke(%{role: %Role{id: _pid} = role}, %Feature{id: _id} = feature) do
    revoke(role, feature)
  end

  def revoke(%{feature_id: id}, %Feature{id: _id} = feature) do
    revoke(%Role{id: id}, feature)
  end

  def revoke(%Feature{id: id} = _, %Role{id: _id} = role) do
    from(pa in RoleFeatures)
    |> where([pr], pr.feature_id == ^id and pr.role_id == ^role.id)
    |> Repo.delete_all()
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
    FeatureRoles
    |> where(
      [e],
      e.role_id == ^role.id and e.feature_id == ^feature_id
    )
    |> Repo.one()
  end

  def all() do
    Repo.all(Membership.Role)
    |> Enum.map(fn x ->
      features = Enum.map(x.features, fn f -> f.identifier end)
      {x.identifier, features}
    end)
  end
end
