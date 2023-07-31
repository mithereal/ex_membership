defmodule Membership.Repo.Migrations.CreateMemberPlansTable do
  use Ecto.Migration

  def change do
    key_type = Membership.Config.key_type(:migration)

    create table(:membership_member_plans, primary_key: false) do
      add(:id, key_type, primary_key: true)
      add(:member_id, references(Membership.Member.table()))
      add(:assoc_id, :integer)
      add(:features, {:array, :string})

    end
  end
end
