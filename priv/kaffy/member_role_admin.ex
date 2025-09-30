defmodule Membership.MemberRoleAdmin do
  @behaviour Kaffy.ResourceAdmin
  @repo Membership.Repo.repo()

  alias Membership.{MemberRoles, Member, Role}
  import Ecto.Query

  def plural_name(_) do
    "Member Roles"
  end

  def index(conn) do
    MemberRoles.index(conn)
  end

  # Create a new changeset
  def build(_conn), do: %MemberRoles{}

  # Get an entry using simulated composite key
  def get(%{"member_id" => member_id, "role_id" => role_id}) do
    @repo.get_by!(MemberRoles, member_id: member_id, role_id: role_id)
  end

  # Parse Kaffy's string ID like "123:456"
  def get(id) when is_binary(id) do
    [member_id_str, role_id_str] = String.split(id, ":")

    # Convert IDs to integers (or UUIDs if you're using UUIDs)
    {member_id, _} = Integer.parse(member_id_str)
    {role_id, _} = Integer.parse(role_id_str)

    get(%{"member_id" => member_id, "role_id" => role_id})
  end

  # Create a record
  def create(attrs) do
    %MemberRoles{}
    |> MemberRoles.changeset(attrs)
    |> @repo.insert()
  end

  # Update a record
  def update(member_role, attrs) do
    member_role
    |> MemberRoles.changeset(attrs)
    |> @repo.update()
  end

  # Delete a record
  def delete(member_role) do
    @repo.delete(member_role)
  end

  # Define how the form looks
  def changeset(schema, params) do
    MemberRoles.changeset(schema, params)
  end

  def form_fields(_conn) do
    [
      member_id: %{type: :select, choices: member_choices()},
      role_id: %{type: :select, choices: role_choices()}
    ]
  end

  defp member_choices do
    @repo.all(Member)
    |> Enum.map(&{&1.identifier, &1.id})
  end

  defp role_choices do
    @repo.all(Role)
    |> Enum.map(&{&1.name, &1.id})
  end

  # Simulate ordering
  @impl true
  def ordering(_schema) do
    [asc: :member_id]
  end
end
