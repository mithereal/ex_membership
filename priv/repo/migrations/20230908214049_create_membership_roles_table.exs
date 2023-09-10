defmodule Membership.Repo.Migrations.CreateMemberRolesTable do
  use Ecto.Migration

  def change do
    key_type = Membership.Config.key_type(:migration)

    create table(:membership_member_roles, primary_key: false) do
      add(:member_id, references(Membership.Member.table(), type: key_type))
      add(:role_id, references(Membership.Role.table(), type: key_type))
    end
  end
end
