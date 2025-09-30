defmodule Membership.RoleFeatures do
  @moduledoc false

  use Membership.Schema, type: :binary_fk

  alias Membership.Feature
  alias Membership.Role
  alias Membership.RoleFeatures

  schema "membership_role_features" do
    # Virtual ID field (for Kaffy)
    field(:id, :string, virtual: true)

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

  def index(_conn) do
    repo = Membership.Repo.repo()

    repo.all(RoleFeatures)
    |> Enum.map(&with_virtual_id/1)
  end

  def get(%{"role_id" => role_id, "feature_id" => feature_id}) do
    repo = Membership.Repo.repo()

    repo.get_by!(RoleFeatures, role_id: role_id, feature_id: feature_id)
    |> with_virtual_id()
  end

  def get(id) when is_binary(id) do
    case String.split(id, ":") do
      [role_id_str, feature_id_str] ->
        get(%{"role_id" => role_id_str, "feature_id" => feature_id_str})

      _ ->
        raise "Invalid ID format. Expected 'role_id:feature_id'"
    end
  end

  defp with_virtual_id(struct) do
    %{struct | id: "#{struct.role_id}:#{struct.feature_id}"}
  end
end
