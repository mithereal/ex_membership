defmodule Membership.Repo.Migrations.CreateMembershipFeaturesTable do
  use Ecto.Migration

  def change do
    key_type = Membership.Config.key_type(:migration)

    create table(:membership_member_features, primary_key: false) do
      add(:id, key_type, primary_key: true)

      add(:member_id, references(Membership.Member.table()))
      add(:feature_id, references(Membership.Feature.table()))
    end
  end
end
