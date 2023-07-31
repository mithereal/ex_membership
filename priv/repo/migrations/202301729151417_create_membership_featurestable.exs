defmodule Membership.Repo.Migrations.CreateMembershipFeaturesTable do
  use Ecto.Migration

  def change do
    create table(:membership_member_features) do
      add(:member_id, references(Membership.Member.table()))
      add(:assoc_id, :integer)
      add(:features, {:array, :string})

      timestamps()
    end
  end
end
