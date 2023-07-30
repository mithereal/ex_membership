defmodule Membership.Repo.Migrations.CreateMemberPlansTable do
  use Ecto.Migration

  def change do
    create table(:membership_member_plans) do
      add(:member_id, references(Membership.Member.table()))
      add(:assoc_id, :integer)
      add(:features, {:array, :string})

    end
  end
end
