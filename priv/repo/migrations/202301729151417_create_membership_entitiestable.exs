defmodule Membership.Repo.Migrations.CreateMembershipEntitiesTable do
  use Ecto.Migration

  def change do
    create table(:membership_member_entities) do
      add(:member_id, references(Membership.Member.table()))
      add(:assoc_id, :integer)
      add(:assoc_type, :string)
      add(:features, {:array, :string})

      timestamps()
    end
  end
end
