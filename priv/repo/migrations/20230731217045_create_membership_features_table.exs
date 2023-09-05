defmodule Membership.Repo.Migrations.CreateMembershipFeaturesTable do
  use Ecto.Migration

  def change do
    key_type = Membership.Config.key_type(:migration)

    create table(:membership_member_features, primary_key: false) do
      add(:member_id, references(Membership.Member.table(), type: key_type))
      add(:feature_id, references(Membership.Feature.table(), type: key_type))
      add(:permission, :string)
    end
  end
end
