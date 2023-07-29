defmodule Membership.Repo.Migrations.CreateMembersEntitiesTable do
  use Ecto.Migration

  def change do
    create table(:membership_member_plans) do
      add(:member_id, references(Membership.Member.table()))
      add(:assoc_id, :integer)
      add(:plans, {:array, :string})

      timestamps()
    end
  end
end
