defmodule Membership.Repo.Migrations.CreateMemberPlansTable do
  use Ecto.Migration

  def change do
    key_type = Membership.key_type(:migration)

    create table(:membership_member_plans, primary_key: false) do
      add(:member_id, references(Membership.Member.table(), type: key_type))
      add(:plan_id, references(Membership.Plan.table(), type: key_type))
    end
  end
end
