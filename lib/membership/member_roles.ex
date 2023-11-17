defmodule Membership.MemberRoles do
  @moduledoc false

  use Membership.Schema, type: :binary_fk

  alias Membership.Member
  alias Membership.Role
  alias Membership.MemberRoles

  schema "membership_member_roles" do
    belongs_to(:member, Member)
    belongs_to(:role, Role)
  end

  def changeset(%MemberRoles{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:member_id, :role_id])
    |> validate_required([:member_id, :role_id])
  end

  def create(
        %Member{id: id},
        %{__struct__: _role_name, id: role_id}
      ) do
    changeset(%MemberRoles{
      member_id: id,
      role_id: role_id
    })
    |> Repo.insert!()
  end

  def table, do: :membership_features
end
