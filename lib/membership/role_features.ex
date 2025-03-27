defmodule Membership.RoleFeatures do
  @moduledoc false

  use Membership.Schema, type: :binary_fk

  alias Membership.Feature
  alias Membership.Role
  alias Membership.RoleFeatures

  @config Membership.Config.new()

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
    changeset =
      changeset(%RoleFeatures{
        feature_id: id,
        role_id: assoc_id
      })

    @config |> Repo.insert!(changeset)
  end
end
