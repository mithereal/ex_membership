defmodule Membership.RoleFeatures do
  @moduledoc false

  use Membership.Schema, type: :binary_fk

  alias Membership.Feature
  alias Membership.Role
  alias Membership.RoleFeatures

  schema "membership_role_features" do
    belongs_to(:feature, Feature)
    belongs_to(:role, Role)
  end

  def changeset(%RoleFeatures{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:feature_id, :role_id])
    |> validate_required([:feature_id, :role_id])
  end

  def create(
        %Feature{id: id},
        %{__struct__: _role_name, id: assoc_id},
        _features \\ []
      ) do
    repo = Membership.Repo.repo()

    changeset(%RoleFeatures{
      feature_id: id,
      role_id: assoc_id
    })
    |> repo.insert!()
  end

  def table, do: :membership_role_features
end
