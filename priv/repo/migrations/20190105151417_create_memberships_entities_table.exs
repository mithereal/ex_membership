defmodule Membership.Repo.Migrations.CreateMembersEntitiesTable do
  use Ecto.Migration

  def change do
    create table(:membership_members_entities) do
      add(:member_id, references(Membership.Member.table()))
      add(:assoc_id, :integer)
      add(:assoc_type, :string)
      add(:abilities, {:array, :string})

      timestamps()
    end
  end
end
