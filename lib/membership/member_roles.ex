defmodule Membership.MemberRoles do
  @moduledoc """
  MemberFeatures is the association linking the member to the feature you can also set specific features for the membership
  """

  use Membership.Schema, type: :binary_fk

  alias Membership.Member
  alias Membership.Role
  alias Membership.MemberRoles

  schema "membership_member_roles" do
    # Virtual ID field (for Kaffy)
    field(:id, :string, virtual: true)

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
    repo = Membership.Repo.repo()

    changeset(%MemberRoles{
      member_id: id,
      role_id: role_id
    })
    |> repo.insert!()
  end

  def table, do: :membership_member_roles

  def index(_conn) do
    Repo.all(MemberRoles)
    |> Enum.map(&with_virtual_id/1)
  end

  def get(%{"member_id" => member_id, "role_id" => role_id}) do
    Repo.get_by!(MemberRoles, member_id: member_id, role_id: role_id)
    |> with_virtual_id()
  end

  def get(id) when is_binary(id) do
    case String.split(id, ":") do
      [member_id_str, role_id_str] ->
        get(%{"member_id" => member_id_str, "role_id" => role_id_str})

      _ ->
        raise "Invalid ID format. Expected 'member_id:role_id'"
    end
  end

  defp with_virtual_id(struct) do
    %{struct | id: "#{struct.member_id}:#{struct.role_id}"}
  end
end
